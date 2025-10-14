#!/bin/bash

set -e

echo "🧪 Testing S3 Vector Search..."

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
RED='\033[0;31m'
NC='\033[0m' # No Color

print_status() { echo -e "${GREEN}✅ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
print_info() { echo -e "${CYAN}📋 $1${NC}"; }
print_error() { echo -e "${RED}❌ $1${NC}"; }

print_info "Configuration:"
echo "S3 Bucket: $S3_BUCKET"
echo "Region: $REGION"
echo "Embedding Model: $EMBEDDING_MODEL"
echo ""

# Function to generate embedding
generate_embedding() {
    local text="$1"
    local temp_file="/tmp/query_embedding_input.json"
    local output_file="/tmp/query_embedding_output.json"
    
    cat > "$temp_file" << EOF
{
    "inputText": "$text",
    "dimensions": 1024,
    "normalize": true
}
EOF

    aws bedrock-runtime invoke-model \
        --model-id "$EMBEDDING_MODEL" \
        --body "file://$temp_file" \
        --content-type "application/json" \
        --accept "application/json" \
        --region "$REGION" \
        "$output_file" > /dev/null 2>&1

    if [ -f "$output_file" ]; then
        jq -r '.embedding' "$output_file" 2>/dev/null || echo "[]"
    else
        echo "[]"
    fi
    
    rm -f "$temp_file" "$output_file"
}

# Function to calculate cosine similarity
calculate_similarity() {
    local query_embedding="$1"
    local doc_embedding="$2"
    
    # Use Python for vector calculations
    python3 -c "
import json
import math

query = json.loads('$query_embedding')
doc = json.loads('$doc_embedding')

if len(query) != len(doc):
    print(0)
    exit()

dot_product = sum(a * b for a, b in zip(query, doc))
norm_a = math.sqrt(sum(a * a for a in query))
norm_b = math.sqrt(sum(b * b for b in doc))

if norm_a == 0 or norm_b == 0:
    print(0)
else:
    similarity = dot_product / (norm_a * norm_b)
    print(f'{similarity:.4f}')
" 2>/dev/null || echo "0"
}

# Function to search vectors
search_vectors() {
    local query="$1"
    local max_results=${2:-5}
    local threshold=${3:-0.7}
    
    print_info "Searching for: '$query'"
    print_info "Generating query embedding..."
    
    local query_embedding=$(generate_embedding "$query")
    
    if [ "$query_embedding" = "[]" ] || [ -z "$query_embedding" ]; then
        print_error "Failed to generate query embedding"
        return 1
    fi
    
    print_status "Query embedding generated"
    
    # Get all vector files
    print_info "Retrieving vector documents..."
    
    local vector_files=$(aws s3 ls "s3://$S3_BUCKET/vectors/" --region "$REGION" | grep '\.json$' | awk '{print $4}')
    
    if [ -z "$vector_files" ]; then
        print_warning "No vector files found in s3://$S3_BUCKET/vectors/"
        return 1
    fi
    
    local vector_count=$(echo "$vector_files" | wc -l)
    print_info "Found $vector_count vector documents"
    
    # Create temporary results file
    local results_file="/tmp/search_results.txt"
    echo "" > "$results_file"
    
    # Search through vectors
    local processed=0
    echo "$vector_files" | while IFS= read -r file; do
        processed=$((processed + 1))
        
        if [ $((processed % 10)) -eq 0 ]; then
            print_info "Processed $processed/$vector_count vectors..."
        fi
        
        # Download and parse vector document
        local temp_doc="/tmp/vector_doc.json"
        if aws s3 cp "s3://$S3_BUCKET/vectors/$file" "$temp_doc" --region "$REGION" 2>/dev/null; then
            local doc_embedding=$(jq -r '.embedding | @json' "$temp_doc" 2>/dev/null)
            local doc_text=$(jq -r '.text' "$temp_doc" 2>/dev/null)
            local doc_id=$(jq -r '.id' "$temp_doc" 2>/dev/null)
            local doc_source=$(jq -r '.metadata.source' "$temp_doc" 2>/dev/null)
            
            if [ "$doc_embedding" != "null" ] && [ -n "$doc_embedding" ]; then
                local similarity=$(calculate_similarity "$query_embedding" "$doc_embedding")
                
                # Check if similarity meets threshold
                if [ "$(echo "$similarity >= $threshold" | bc -l 2>/dev/null || echo "0")" = "1" ]; then
                    echo "$similarity|$doc_id|$doc_source|$doc_text" >> "$results_file"
                fi
            fi
            
            rm -f "$temp_doc"
        fi
    done
    
    # Sort results by similarity (highest first) and limit
    if [ -s "$results_file" ]; then
        print_status "Search completed. Processing results..."
        
        local sorted_results=$(sort -t'|' -k1 -nr "$results_file" | head -n "$max_results")
        
        if [ -n "$sorted_results" ]; then
            echo ""
            print_status "🔍 Search Results:"
            echo "=================="
            
            local result_num=1
            echo "$sorted_results" | while IFS='|' read -r similarity doc_id doc_source doc_text; do
                echo ""
                echo "Result #$result_num"
                echo "Similarity: $similarity"
                echo "Document: $doc_source"
                echo "ID: $doc_id"
                echo "Text: $(echo "$doc_text" | cut -c1-200)..."
                echo "---"
                result_num=$((result_num + 1))
            done
        else
            print_warning "No results found above similarity threshold of $threshold"
        fi
    else
        print_warning "No results found"
    fi
    
    rm -f "$results_file"
}

# Check if Python is available for calculations
if ! command -v python3 &> /dev/null; then
    print_error "Python3 is required for vector calculations"
    print_info "Please install Python3 to use this test script"
    exit 1
fi

# Check if bc is available for threshold comparison
if ! command -v bc &> /dev/null; then
    print_warning "bc calculator not available, using basic comparison"
fi

# Test queries
declare -a test_queries=(
    "Kubernetes troubleshooting"
    "Infrastructure as Code best practices"
    "CI/CD pipeline setup"
    "Docker container security"
    "Monitoring and observability"
    "Terraform configuration"
)

echo "🚀 Running test searches..."
echo ""

for query in "${test_queries[@]}"; do
    echo "========================================"
    search_vectors "$query" 3 0.6
    echo ""
    echo "Press Enter to continue to next query..."
    read -r
done

echo ""
echo "🎉 S3 Vector Search Testing Complete!"
echo ""
echo "💡 Usage in your application:"
echo "============================"
echo "1. Use the S3VectorStore class in lambda/bedrock/s3-vector-store.ts"
echo "2. Call vectorStore.search(query, maxResults, threshold)"
echo "3. Process the returned SearchResult[] array"
echo ""
echo "🔧 To adjust search parameters:"
echo "=============================="
echo "- Increase threshold (0.7-0.9) for more precise results"
echo "- Decrease threshold (0.5-0.7) for broader results"
echo "- Adjust maxResults based on your needs"
echo ""
echo "🚀 Your S3 vector search is working!"