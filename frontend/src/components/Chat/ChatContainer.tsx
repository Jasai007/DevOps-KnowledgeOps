import React, { useState, useEffect, useRef } from 'react';
import {
  Box,
  Container,
  useTheme,
  useMediaQuery,
  Fab,
  Zoom,
  Chip,
} from '@mui/material';
import {
  KeyboardArrowDown as ScrollDownIcon,
  Memory as MemoryIcon,
} from '@mui/icons-material';
import MessageBubble, { Message } from './MessageBubble';
import ChatInput from './ChatInput';
import SuggestionChips from './SuggestionChips';
import { apiService } from '../../services/api';
import { useAuth } from '../../contexts/AuthContext';

// Extended message interface for chat container
interface ExtendedMessage extends Message {
  metadata?: {
    responseTime?: number;
    confidence?: number;
    sessionId?: string;
    messageCount?: number;
    contextUsed?: boolean;
  };
}

interface ChatContainerProps {
  sessionId?: string;
  onSessionChange?: (sessionId: string) => void;
  onNewMessage?: () => void;
}

const ChatContainer: React.FC<ChatContainerProps> = ({
  sessionId: propSessionId,
  onSessionChange,
  onNewMessage
}) => {
  const [messages, setMessages] = useState<ExtendedMessage[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [showSuggestions, setShowSuggestions] = useState(true);
  const [showScrollButton, setShowScrollButton] = useState(false);
  const [sessionId, setSessionId] = useState<string | null>(propSessionId || null);
  const [lastAuthState, setLastAuthState] = useState<boolean>(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);
  const chatContainerRef = useRef<HTMLDivElement>(null);

  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const { isAuthenticated, user } = useAuth();

  useEffect(() => {
    // Handle authentication state changes
    if (isAuthenticated !== lastAuthState) {
      setLastAuthState(isAuthenticated);
      
      if (isAuthenticated) {
        // User just logged in - force new session to prevent 403 errors
        console.log('User logged in, creating new session');
        setSessionId(null);
        setMessages([]);
        initializeNewChat();
        return;
      } else {
        // User logged out - clear session data
        console.log('User logged out, clearing session');
        setSessionId(null);
        setMessages([]);
        setShowSuggestions(true);
        return;
      }
    }

    // Handle session changes from props
    if (propSessionId && propSessionId !== sessionId) {
      setSessionId(propSessionId);
      loadSessionMessages(propSessionId);
    } else if (propSessionId === undefined && sessionId) {
      // New chat requested - clear current session
      setSessionId(null);
      initializeNewChat();
    } else if (!propSessionId && !sessionId && isAuthenticated) {
      // Initialize new session and welcome message
      initializeNewChat();
    }
  }, [propSessionId, isAuthenticated, lastAuthState]);

  const initializeNewChat = async () => {
    // Clear current session and messages
    setSessionId(null);
    setMessages([]);
    
    // Only create session if user is authenticated
    if (isAuthenticated) {
      try {
        // Always create a new session for new chat
        const sessionResponse = await apiService.createSession();
        if (sessionResponse.success && sessionResponse.session) {
          const newSessionId = sessionResponse.session.sessionId;
          setSessionId(newSessionId);
          onSessionChange?.(newSessionId);
          console.log('Created new session:', newSessionId);
        }
      } catch (error) {
        console.error('Failed to create session:', error);
      }
    }

    const welcomeMessage: ExtendedMessage = {
      id: 'welcome',
      role: 'assistant',
      content: isAuthenticated ? 
        `👋 Welcome back${user?.email ? `, ${user.email.split('@')[0]}` : ''}! 

I'm your AI-powered DevOps expert, built with Amazon Bedrock AgentCore. I can help you with:

🔧 **Infrastructure & Cloud**: AWS, Azure, GCP, hybrid setups
🚀 **CI/CD Pipelines**: GitHub Actions, Jenkins, GitLab CI, AWS CodePipeline  
📦 **Containers**: Docker, Kubernetes, EKS, container orchestration
📊 **Monitoring**: Prometheus, Grafana, CloudWatch, observability
🔒 **Security**: DevSecOps practices, compliance, vulnerability management
⚡ **Automation**: Terraform, Ansible, Infrastructure as Code
🐛 **Troubleshooting**: System debugging, performance optimization

I'll remember our conversation as we chat, so feel free to ask follow-up questions or refer to previous topics!

What DevOps challenge can I help you solve today?` :
        `👋 Welcome to the DevOps KnowledgeOps Agent!

Please sign in to start a conversation with your AI-powered DevOps expert.

Once logged in, I can help you with infrastructure, CI/CD, containers, monitoring, security, and more!`,
      timestamp: new Date(),
    };

    setMessages([welcomeMessage]);
    setShowSuggestions(isAuthenticated);
    scrollToBottom();
  };

  const loadSessionMessages = async (sessionIdToLoad: string) => {
    console.log('Loading messages for session:', sessionIdToLoad);
    try {
      const response = await apiService.getSessionMessages(sessionIdToLoad);
      if (response.success && response.messages && response.messages.length > 0) {
        const loadedMessages: ExtendedMessage[] = response.messages.map((msg: any) => ({
          id: msg.messageId || msg.id,
          role: msg.role,
          content: msg.content,
          timestamp: new Date(msg.timestamp),
          metadata: msg.metadata,
        }));
        setMessages(loadedMessages);
        setShowSuggestions(false);
        console.log('Loaded', loadedMessages.length, 'messages');
      } else {
        // If no messages found, start with empty session
        console.log('No messages found for session, starting empty');
        setMessages([]);
        setShowSuggestions(true);
      }
    } catch (error) {
      console.error('Failed to load session messages:', error);
      setMessages([]);
      setShowSuggestions(true);
    }
  };

  useEffect(() => {
    // Initialize chat on first load if no session is provided
    if (!propSessionId && messages.length === 0) {
      initializeNewChat();
    }
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  useEffect(() => {
    const handleScroll = () => {
      if (chatContainerRef.current) {
        const { scrollTop, scrollHeight, clientHeight } = chatContainerRef.current;
        const isNearBottom = scrollHeight - scrollTop - clientHeight < 100;
        setShowScrollButton(!isNearBottom && messages.length > 3);
      }
    };

    const container = chatContainerRef.current;
    if (container) {
      container.addEventListener('scroll', handleScroll);
      return () => container.removeEventListener('scroll', handleScroll);
    }
  }, [messages.length]);

  const scrollToBottom = (smooth: boolean = true) => {
    messagesEndRef.current?.scrollIntoView({
      behavior: smooth ? 'smooth' : 'auto'
    });
  };

  const handleSendMessage = async (messageText: string) => {
    // Check if user is authenticated
    if (!isAuthenticated) {
      console.error('User not authenticated');
      return;
    }

    setShowSuggestions(false);
    setIsLoading(true);

    // Add user message
    const userMessage: ExtendedMessage = {
      id: Date.now().toString(),
      role: 'user',
      content: messageText,
      timestamp: new Date(),
    };

    setMessages(prev => [...prev, userMessage]);

    // Add typing indicator
    const typingMessage: ExtendedMessage = {
      id: 'typing',
      role: 'assistant',
      content: '',
      timestamp: new Date(),
      typing: true,
    };

    setMessages(prev => [...prev, typingMessage]);

    try {
      // Get response from real API service with session context
      const apiResponse = await apiService.sendMessage(messageText, sessionId || undefined);
      
      if (!apiResponse.success) {
        throw new Error(apiResponse.error || 'Failed to get response');
      }

      const response = apiResponse.response || 'Sorry, I encountered an error processing your request.';

      // Update session ID if it was created by the server
      if (apiResponse.sessionId && apiResponse.sessionId !== sessionId) {
        setSessionId(apiResponse.sessionId);
        onSessionChange?.(apiResponse.sessionId);
        console.log('Updated session ID:', apiResponse.sessionId);
      }

      // Remove typing indicator and add real response
      setMessages(prev => {
        const filtered = prev.filter(msg => msg.id !== 'typing');
        const assistantMessage: ExtendedMessage = {
          id: Date.now().toString(),
          role: 'assistant',
          content: response,
          timestamp: new Date(),
        };

        // Add session info to metadata if available
        if (apiResponse.metadata) {
          assistantMessage.metadata = {
            ...apiResponse.metadata,
            sessionId: apiResponse.sessionId
          };
        }

        return [...filtered, assistantMessage];
      });

      // Notify parent that a new message was added (to refresh chat history)
      onNewMessage?.();

    } catch (error) {
      console.error('Error sending message:', error);
      setMessages(prev => {
        const filtered = prev.filter(msg => msg.id !== 'typing');
        
        // Check if it's a 403 error (authentication issue)
        const errorMessage = error instanceof Error && error.message.includes('403') ?
          '🔒 Authentication error. Please try refreshing the page or logging in again.' :
          '❌ I encountered an issue processing your request. Please try again.';
        
        return [...filtered, {
          id: Date.now().toString(),
          role: 'assistant',
          content: errorMessage,
          timestamp: new Date(),
        }];
      });
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <Box sx={{
      height: '100%',
      display: 'flex',
      flexDirection: 'column',
      position: 'relative',
    }}>
      {/* Session Status */}
      {sessionId && (
        <Box sx={{
          position: 'sticky',
          top: 0,
          zIndex: 100,
          bgcolor: 'background.paper',
          borderBottom: 1,
          borderColor: 'divider',
          px: 2,
          py: 1
        }}>
          <Container maxWidth="md">
            <Chip
              icon={<MemoryIcon />}
              label={`Session Active - Conversation Memory Enabled`}
              size="small"
              color="primary"
              variant="outlined"
            />
          </Container>
        </Box>
      )}

      {/* Chat Messages Area */}
      <Box
        ref={chatContainerRef}
        sx={{
          flex: 1,
          overflow: 'auto',
          pb: { xs: 12, sm: 2 }, // Extra padding on mobile for fixed input
          position: 'relative',
        }}
      >
        <Container
          maxWidth="md"
          sx={{
            py: { xs: 1, sm: 2 },
            px: { xs: 0, sm: 2 },
          }}
        >
          {messages.map((message) => (
            <MessageBubble key={message.id} message={message as Message} />
          ))}

          {/* Suggestions */}
          <SuggestionChips
            show={showSuggestions && messages.length <= 1}
            onSuggestionClick={handleSendMessage}
          />

          <div ref={messagesEndRef} />
        </Container>
      </Box>

      {/* Scroll to Bottom Button */}
      <Zoom in={showScrollButton}>
        <Fab
          size="small"
          color="primary"
          onClick={() => scrollToBottom()}
          sx={{
            position: 'absolute',
            bottom: { xs: 100, sm: 80 },
            right: { xs: 16, sm: 24 },
            zIndex: 1000,
          }}
        >
          <ScrollDownIcon />
        </Fab>
      </Zoom>

      {/* Chat Input */}
      {!isMobile && (
        <Container maxWidth="md" sx={{ px: { xs: 1, sm: 2 } }}>
          <ChatInput
            onSendMessage={handleSendMessage}
            isLoading={isLoading}
          />
        </Container>
      )}

      {/* Mobile Chat Input (Fixed) */}
      {isMobile && (
        <ChatInput
          onSendMessage={handleSendMessage}
          isLoading={isLoading}
        />
      )}
    </Box>
  );
};

export default ChatContainer;