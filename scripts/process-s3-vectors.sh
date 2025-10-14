#!/bin/bash

set -e

echo "🔄 Processing documents and creating embeddings in S3..."

# Load configuration if available
if [ -f "s3-vector-config.env" ]; then
    source s3-vector-config.env
    echo "✅ Loaded configuration from s3-vector-config.env"
fi

# Configuration
REGION=${AWS_REGION:-us-east-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
S3_BUCKET=${KNOWLEDGE_BUCKET_NAME:-"devops-knowledge-$ACCOUNT_ID-$REGION"}
EMBEDDING_MODEL=${EMBEDDING_MODEL:-"amazon.titan-embed-text-v2:0"}

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${CYAN}📋 $1${NC}"; }

print_info "Configuration:"
echo "S3 Bucket: $S3_BUCKET"
echo "Region: $REGION"
echo "Embedding Model: $EMBEDDING_MODEL"
echo ""

# Function to generate embedding using Bedrock
generate_embedding() {
    local text="$1"
    local temp_file="/tmp/embedding_input.json"
    local output_file="/tmp/embedding_output.json"
    
    # Create input JSON
    cat > "$temp_file" << EOF
{
    "inputText": "$text",
    "dimensions": 1024,
    "normalize": true
}
EOF

    # Call Bedrock to generate embedding
    aws bedrock-runtime invoke-model \
        --model-id "$EMBEDDING_MODEL" \
        --body "file://$temp_file" \
        --content-type "application/json" \
        --accept "application/json" \
        --region "$REGION" \
        "$output_file" > /dev/null 2>&1

    # Extract embedding from response
    if [ -f "$output_file" ]; then
        jq -r '.embedding | @json' "$output_file" 2>/dev/null || echo "[]"
    else
        echo "[]"
    fi
    
    # Clean up
    rm -f "$temp_file" "$output_file"
}

# Function to chunk text
chunk_text() {
    local text="$1"
    local chunk_size=${2:-1000}
    local chunk_overlap=${3:-200}
    
    # Simple word-based chunking
    echo "$text" | fold -w $chunk_size -s
}

# Function to process a single document
process_document() {
    local s3_key="$1"
    local local_file="/tmp/$(basename "$s3_key")"
    
    print_info "Processing: $s3_key"
    
    # Download document
    if ! aws s3 cp "s3://$S3_BUCKET/$s3_key" "$local_file" --region "$REGION" 2>/dev/null; then
        print_warning "Failed to download $s3_key"
        return 1
    fi
    
    # Read content
    local content=$(cat "$local_file")
    local source=$(basename "$s3_key" .md)
    
    # Clean content (remove markdown headers, etc.)
    content=$(echo "$content" | sed 's/^#.*//g' | sed 's/```.*```//g' | tr -s ' ' | tr '\n' ' ')
    
    # Chunk the content
    local chunk_num=0
    echo "$content" | fold -w 800 -s | while IFS= read -r chunk; do
        if [ -n "$(echo "$chunk" | tr -d ' \t\n')" ]; then
            local doc_id="${source}-chunk-${chunk_num}"
            
            print_info "  Creating embedding for chunk $chunk_num..."
            
            # Generate embedding
            local embedding=$(generate_embedding "$chunk")
            
            if [ "$embedding" != "[]" ] && [ -n "$embedding" ]; then
                # Create document JSON
                local doc_json="/tmp/${doc_id}.json"
                cat > "$doc_json" << EOF
{
    "id": "$doc_id",
    "text": $(echo "$chunk" | jq -R .),
    "embedding": $embedding,
    "metadata": {
        "source": "$source",
        "chunk": $chunk_num,
        "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
        "s3_key": "$s3_key"
    }
}
EOF

                # Upload to S3
                if aws s3 cp "$doc_json" "s3://$S3_BUCKET/vectors/${doc_id}.json" --region "$REGION" 2>/dev/null; then
                    print_status "  ✅ Created vector for chunk $chunk_num"
                else
                    print_warning "  ❌ Failed to upload vector for chunk $chunk_num"
                fi
                
                rm -f "$doc_json"
            else
                print_warning "  ❌ Failed to generate embedding for chunk $chunk_num"
            fi
            
            chunk_num=$((chunk_num + 1))
        fi
    done
    
    rm -f "$local_file"
}

# Get list of documents to process
print_info "Finding documents to process..."

DOCUMENTS=$(aws s3 ls "s3://$S3_BUCKET/knowledge-base/" --recursive --region "$REGION" | grep -E '\.(md|txt)$' | awk '{print $4}' || echo "")

if [ -z "$DOCUMENTS" ]; then
    print_warning "No documents found in s3://$S3_BUCKET/knowledge-base/"
    echo "Please upload some .md or .txt files first using:"
    echo "  aws s3 sync knowledge-base/ s3://$S3_BUCKET/knowledge-base/"
    exit 1
fi

echo "Found documents:"
echo "$DOCUMENTS"
echo ""

# Process each document
total_docs=$(echo "$DOCUMENTS" | wc -l)
current_doc=0

echo "$DOCUMENTS" | while IFS= read -r doc; do
    current_doc=$((current_doc + 1))
    print_info "Processing document $current_doc/$total_docs: $doc"
    
    if process_document "$doc"; then
        print_status "Completed processing: $doc"
    else
        print_warning "Failed to process: $doc"
    fi
    
    echo ""
done

# Create index
print_info "Creating search index..."

VECTOR_COUNT=$(aws s3 ls "s3://$S3_BUCKET/vectors/" --region "$REGION" | wc -l)

cat > /tmp/index.json << EOF
{
    "totalVectors": $VECTOR_COUNT,
    "lastUpdated": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "embeddingModel": "$EMBEDDING_MODEL",
    "dimensions": 1024,
    "chunkSize": 800,
    "searchAlgorithm": "cosine",
    "status": "ready"
}
EOF

aws s3 cp /tmp/index.json "s3://$S3_BUCKET/index/index.json" --region "$REGION"
rm -f /tmp/index.json

print_status "Created search index"

echo ""
echo "🎉 Vector Processing Complete!"
echo ""
echo "📊 Summary:"
echo "==========="
echo "Documents processed: $total_docs"
echo "Vectors created: $VECTOR_COUNT"
echo "S3 Bucket: $S3_BUCKET"
echo "Index location: s3://$S3_BUCKET/index/index.json"
echo ""
echo "💡 Next Steps:"
echo "=============="
echo "1. Test vector search: ./scripts/test-s3-vector-search.sh"
echo "2. Use the S3VectorStore class in your Lambda functions"
echo "3. Query your knowledge base through the chat interface"
echo ""
echo "🔍 To view created vectors:"
echo "=========================="
echo "aws s3 ls s3://$S3_BUCKET/vectors/ --region $REGION"
echo ""
echo "🚀 Your S3 vector store is ready for use!"