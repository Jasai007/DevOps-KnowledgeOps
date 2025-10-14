import { S3Client, GetObjectCommand, PutObjectCommand, ListObjectsV2Command } from '@aws-sdk/client-s3';
import { BedrockRuntimeClient, InvokeModelCommand } from '@aws-sdk/client-bedrock-runtime';

export interface VectorDocument {
  id: string;
  text: string;
  embedding: number[];
  metadata: {
    source: string;
    chunk: number;
    timestamp: string;
    [key: string]: any;
  };
}

export interface SearchResult {
  document: VectorDocument;
  similarity: number;
}

export interface S3VectorStoreConfig {
  bucketName: string;
  vectorPrefix: string;
  documentsPrefix: string;
  indexPrefix: string;
  embeddingModel: string;
  dimensions: number;
  region?: string;
}

export class S3VectorStore {
  private s3Client: S3Client;
  private bedrockClient: BedrockRuntimeClient;
  private config: S3VectorStoreConfig;

  constructor(config: S3VectorStoreConfig) {
    this.config = config;
    const region = config.region || 'us-east-1';
    
    this.s3Client = new S3Client({ region });
    this.bedrockClient = new BedrockRuntimeClient({ region });
  }

  /**
   * Generate embeddings for text using Amazon Titan
   */
  async generateEmbedding(text: string): Promise<number[]> {
    try {
      const command = new InvokeModelCommand({
        modelId: this.config.embeddingModel,
        body: JSON.stringify({
          inputText: text,
          dimensions: this.config.dimensions,
          normalize: true
        }),
        contentType: 'application/json',
        accept: 'application/json'
      });

      const response = await this.bedrockClient.send(command);
      const responseBody = JSON.parse(new TextDecoder().decode(response.body));
      
      return responseBody.embedding;
    } catch (error) {
      console.error('Error generating embedding:', error);
      throw error;
    }
  }

  /**
   * Store a document with its embedding in S3
   */
  async storeDocument(document: VectorDocument): Promise<void> {
    try {
      const key = `${this.config.vectorPrefix}${document.id}.json`;
      
      const command = new PutObjectCommand({
        Bucket: this.config.bucketName,
        Key: key,
        Body: JSON.stringify(document),
        ContentType: 'application/json',
        Metadata: {
          source: document.metadata.source,
          chunk: document.metadata.chunk.toString(),
          timestamp: document.metadata.timestamp
        }
      });

      await this.s3Client.send(command);
    } catch (error) {
      console.error('Error storing document:', error);
      throw error;
    }
  }

  /**
   * Process and store a text document by chunking and embedding
   */
  async processAndStoreDocument(
    text: string, 
    source: string, 
    chunkSize: number = 1000, 
    chunkOverlap: number = 200
  ): Promise<string[]> {
    const chunks = this.chunkText(text, chunkSize, chunkOverlap);
    const documentIds: string[] = [];

    for (let i = 0; i < chunks.length; i++) {
      const chunk = chunks[i];
      const embedding = await this.generateEmbedding(chunk);
      
      const document: VectorDocument = {
        id: `${source}-chunk-${i}`,
        text: chunk,
        embedding,
        metadata: {
          source,
          chunk: i,
          timestamp: new Date().toISOString(),
          totalChunks: chunks.length
        }
      };

      await this.storeDocument(document);
      documentIds.push(document.id);
    }

    return documentIds;
  }

  /**
   * Search for similar documents using cosine similarity
   */
  async search(query: string, maxResults: number = 10, threshold: number = 0.7): Promise<SearchResult[]> {
    try {
      // Generate embedding for the query
      const queryEmbedding = await this.generateEmbedding(query);
      
      // List all vector documents
      const documents = await this.getAllDocuments();
      
      // Calculate similarities
      const results: SearchResult[] = [];
      
      for (const doc of documents) {
        const similarity = this.cosineSimilarity(queryEmbedding, doc.embedding);
        
        if (similarity >= threshold) {
          results.push({
            document: doc,
            similarity
          });
        }
      }

      // Sort by similarity (highest first) and limit results
      return results
        .sort((a, b) => b.similarity - a.similarity)
        .slice(0, maxResults);
        
    } catch (error) {
      console.error('Error searching documents:', error);
      throw error;
    }
  }

  /**
   * Get all stored documents from S3
   */
  private async getAllDocuments(): Promise<VectorDocument[]> {
    const documents: VectorDocument[] = [];
    
    try {
      const listCommand = new ListObjectsV2Command({
        Bucket: this.config.bucketName,
        Prefix: this.config.vectorPrefix
      });

      const response = await this.s3Client.send(listCommand);
      
      if (response.Contents) {
        for (const object of response.Contents) {
          if (object.Key && object.Key.endsWith('.json')) {
            try {
              const getCommand = new GetObjectCommand({
                Bucket: this.config.bucketName,
                Key: object.Key
              });
              
              const getResponse = await this.s3Client.send(getCommand);
              const content = await getResponse.Body?.transformToString();
              
              if (content) {
                const document = JSON.parse(content) as VectorDocument;
                documents.push(document);
              }
            } catch (error) {
              console.error(`Error loading document ${object.Key}:`, error);
            }
          }
        }
      }
    } catch (error) {
      console.error('Error listing documents:', error);
      throw error;
    }

    return documents;
  }

  /**
   * Calculate cosine similarity between two vectors
   */
  private cosineSimilarity(a: number[], b: number[]): number {
    if (a.length !== b.length) {
      throw new Error('Vectors must have the same length');
    }

    let dotProduct = 0;
    let normA = 0;
    let normB = 0;

    for (let i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    normA = Math.sqrt(normA);
    normB = Math.sqrt(normB);

    if (normA === 0 || normB === 0) {
      return 0;
    }

    return dotProduct / (normA * normB);
  }

  /**
   * Split text into overlapping chunks
   */
  private chunkText(text: string, chunkSize: number, overlap: number): string[] {
    const chunks: string[] = [];
    const words = text.split(/\s+/);
    
    for (let i = 0; i < words.length; i += chunkSize - overlap) {
      const chunk = words.slice(i, i + chunkSize).join(' ');
      if (chunk.trim()) {
        chunks.push(chunk.trim());
      }
    }

    return chunks;
  }

  /**
   * Create an index of all documents for faster searching (optional optimization)
   */
  async createIndex(): Promise<void> {
    try {
      const documents = await this.getAllDocuments();
      
      const index = {
        totalDocuments: documents.length,
        lastUpdated: new Date().toISOString(),
        documents: documents.map(doc => ({
          id: doc.id,
          source: doc.metadata.source,
          chunk: doc.metadata.chunk,
          textPreview: doc.text.substring(0, 100) + '...'
        }))
      };

      const command = new PutObjectCommand({
        Bucket: this.config.bucketName,
        Key: `${this.config.indexPrefix}index.json`,
        Body: JSON.stringify(index, null, 2),
        ContentType: 'application/json'
      });

      await this.s3Client.send(command);
      console.log(`Created index with ${documents.length} documents`);
    } catch (error) {
      console.error('Error creating index:', error);
      throw error;
    }
  }

  /**
   * Delete all vectors (for cleanup)
   */
  async clearVectors(): Promise<void> {
    try {
      const listCommand = new ListObjectsV2Command({
        Bucket: this.config.bucketName,
        Prefix: this.config.vectorPrefix
      });

      const response = await this.s3Client.send(listCommand);
      
      if (response.Contents && response.Contents.length > 0) {
        // Note: In production, you'd want to batch delete these
        for (const object of response.Contents) {
          if (object.Key) {
            await this.s3Client.send(new PutObjectCommand({
              Bucket: this.config.bucketName,
              Key: object.Key,
              Body: ''
            }));
          }
        }
      }
    } catch (error) {
      console.error('Error clearing vectors:', error);
      throw error;
    }
  }
}