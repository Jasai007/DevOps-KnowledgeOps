import React, { useState } from 'react';
import {
  Box,
  Paper,
  Avatar,
  Typography,
  Fade,
  CircularProgress,
  useTheme,
  useMediaQuery,
  IconButton,
} from '@mui/material';
import {
  SmartToy as BotIcon,
  Person as PersonIcon,
  ContentCopy as CopyIcon,
  Check as CheckIcon,
} from '@mui/icons-material';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus } from 'react-syntax-highlighter/dist/esm/styles/prism';

export interface Message {
  id: string;
  role: 'user' | 'assistant';
  content: string;
  timestamp: Date;
  typing?: boolean;
}

interface MessageBubbleProps {
  message: Message;
}

const CodeBlock: React.FC<{ code: string; language?: string }> = ({ code, language }) => {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Failed to copy code:', err);
    }
  };

  return (
    <Box sx={{ position: 'relative', my: 1 }}>
      <Box
        sx={{
          position: 'absolute',
          top: 8,
          right: 8,
          zIndex: 1,
        }}
      >
        <IconButton
          size="small"
          onClick={handleCopy}
          sx={{
            bgcolor: 'rgba(0,0,0,0.6)',
            color: 'white',
            '&:hover': {
              bgcolor: 'rgba(0,0,0,0.8)',
            },
          }}
        >
          {copied ? <CheckIcon fontSize="small" /> : <CopyIcon fontSize="small" />}
        </IconButton>
      </Box>
      <SyntaxHighlighter
        language={language || 'text'}
        style={vscDarkPlus}
        customStyle={{
          borderRadius: 8,
          fontSize: '0.875rem',
          margin: 0,
          paddingTop: 40,
        }}
      >
        {code}
      </SyntaxHighlighter>
    </Box>
  );
};

const MessageContent: React.FC<{ content: string }> = ({ content }) => {
  const parts = content.split(/(```[\s\S]*?```)/);
  const elements: React.ReactNode[] = [];

  parts.forEach((part, index) => {
    if (part.startsWith('```') && part.endsWith('```')) {
      const lines = part.slice(3, -3).split('\n');
      const language = lines[0].trim() || 'text';
      const code = lines.slice(1).join('\n');

      elements.push(
        <CodeBlock key={index} code={code} language={language} />
      );
    } else {
      const lines = part.split('\n');
      lines.forEach((line, lineIndex) => {
        const trimmedLine = line.trim();

        if (trimmedLine.startsWith('# ')) {
          elements.push(
            <Typography
              key={`${index}-${lineIndex}`}
              variant="h4"
              component="h1"
              sx={{
                fontWeight: 'bold',
                fontSize: { xs: '1.25rem', sm: '1.5rem' },
                mb: 2,
                mt: lineIndex > 0 ? 3 : 0,
              }}
            >
              {trimmedLine.substring(2)}
            </Typography>
          );
        } else if (trimmedLine.startsWith('## ')) {
          elements.push(
            <Typography
              key={`${index}-${lineIndex}`}
              variant="h5"
              component="h2"
              sx={{
                fontWeight: 'bold',
                fontSize: { xs: '1.125rem', sm: '1.25rem' },
                mb: 1.5,
                mt: lineIndex > 0 ? 2 : 0,
              }}
            >
              {trimmedLine.substring(3)}
            </Typography>
          );
        } else if (trimmedLine.startsWith('### ')) {
          elements.push(
            <Typography
              key={`${index}-${lineIndex}`}
              variant="h6"
              component="h3"
              sx={{
                fontWeight: 'bold',
                fontSize: { xs: '1rem', sm: '1.125rem' },
                mb: 1,
                mt: lineIndex > 0 ? 1.5 : 0,
              }}
            >
              {trimmedLine.substring(4)}
            </Typography>
          );
        } else {
          const processedLine = line
            .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
            .replace(/\*(.*?)\*/g, '<em>$1</em>')
            .replace(/`(.*?)`/g, '<code style="background: rgba(0,0,0,0.1); padding: 2px 4px; border-radius: 4px; font-family: monospace;">$1</code>')
            .replace(/(\w+\.\w+)/g, '<code style="background: rgba(0,0,0,0.1); padding: 2px 4px; border-radius: 4px; font-family: monospace; color: #1976d2;">$1</code>')
            .replace(/([a-zA-Z0-9_-]+\/[a-zA-Z0-9_-]+(?:\/[a-zA-Z0-9_-]+)*)/g, '<code style="background: rgba(0,0,0,0.1); padding: 2px 4px; border-radius: 4px; font-family: monospace; color: #2e7d32;">$1</code>');

          elements.push(
            <Typography
              key={`${index}-${lineIndex}`}
              variant="body1"
              component="div"
              sx={{
                whiteSpace: 'pre-wrap',
                wordBreak: 'break-word',
                fontSize: { xs: '0.875rem', sm: '1rem' },
                lineHeight: 1.5,
                mb: trimmedLine === '' ? 1 : 0,
              }}
              dangerouslySetInnerHTML={{ __html: processedLine }}
            />
          );
        }
      });
    }
  });

  return <>{elements}</>;
};

const MessageBubble: React.FC<MessageBubbleProps> = ({ message }) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const isUser = message.role === 'user';
  
  return (
    <Fade in={true}>
      <Box
        sx={{
          display: 'flex',
          justifyContent: isUser ? 'flex-end' : 'flex-start',
          mb: { xs: 1.5, sm: 2 },
          alignItems: 'flex-start',
          px: { xs: 1, sm: 0 },
        }}
      >
        {!isUser && (
          <Avatar
            sx={{
              bgcolor: 'primary.main',
              mr: { xs: 0.5, sm: 1 },
              width: { xs: 28, sm: 32 },
              height: { xs: 28, sm: 32 },
              mt: 0.5,
            }}
          >
            <BotIcon fontSize={isMobile ? 'small' : 'medium'} />
          </Avatar>
        )}
        
        <Paper
          elevation={1}
          sx={{
            p: { xs: 1.5, sm: 2 },
            maxWidth: { xs: '85%', sm: '75%', md: '70%' },
            bgcolor: isUser ? 'primary.main' : 'grey.100',
            color: isUser ? 'white' : 'text.primary',
            borderRadius: 2,
            position: 'relative',
            wordBreak: 'break-word',
            '&::before': isUser ? {
              content: '""',
              position: 'absolute',
              top: 8,
              right: -8,
              width: 0,
              height: 0,
              borderLeft: '8px solid',
              borderLeftColor: 'primary.main',
              borderTop: '8px solid transparent',
              borderBottom: '8px solid transparent',
            } : {
              content: '""',
              position: 'absolute',
              top: 8,
              left: -8,
              width: 0,
              height: 0,
              borderRight: '8px solid',
              borderRightColor: 'grey.100',
              borderTop: '8px solid transparent',
              borderBottom: '8px solid transparent',
            },
          }}
        >
          {message.typing ? (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
              <CircularProgress size={16} />
              <Typography variant="body2">Thinking...</Typography>
            </Box>
          ) : (
            <MessageContent content={message.content} />
          )}
          
          <Typography
            variant="caption"
            sx={{
              display: 'block',
              mt: 1,
              opacity: 0.7,
              fontSize: { xs: '0.65rem', sm: '0.7rem' },
            }}
          >
            {message.timestamp.toLocaleTimeString([], { 
              hour: '2-digit', 
              minute: '2-digit' 
            })}
          </Typography>
        </Paper>

        {isUser && (
          <Avatar
            sx={{
              bgcolor: 'secondary.main',
              ml: { xs: 0.5, sm: 1 },
              width: { xs: 28, sm: 32 },
              height: { xs: 28, sm: 32 },
              mt: 0.5,
            }}
          >
            <PersonIcon fontSize={isMobile ? 'small' : 'medium'} />
          </Avatar>
        )}
      </Box>
    </Fade>
  );
};

export default MessageBubble;