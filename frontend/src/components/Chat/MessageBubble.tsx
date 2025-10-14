import React from 'react';
import {
  Box,
  Paper,
  Avatar,
  Typography,
  Fade,
  CircularProgress,
  useTheme,
  useMediaQuery,
} from '@mui/material';
import {
  SmartToy as BotIcon,
  Person as PersonIcon,
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

const MessageContent: React.FC<{ content: string }> = ({ content }) => {
  const parts = content.split(/(```[\s\S]*?```)/);
  
  return (
    <>
      {parts.map((part, index) => {
        if (part.startsWith('```') && part.endsWith('```')) {
          const lines = part.slice(3, -3).split('\n');
          const language = lines[0].trim() || 'text';
          const code = lines.slice(1).join('\n');
          
          return (
            <Box key={index} sx={{ my: 1 }}>
              <SyntaxHighlighter
                language={language}
                style={vscDarkPlus}
                customStyle={{
                  borderRadius: 8,
                  fontSize: '0.875rem',
                  margin: 0,
                }}
              >
                {code}
              </SyntaxHighlighter>
            </Box>
          );
        } else {
          return (
            <Typography
              key={index}
              variant="body1"
              component="div"
              sx={{
                whiteSpace: 'pre-wrap',
                wordBreak: 'break-word',
                '& strong': { fontWeight: 'bold' },
                fontSize: { xs: '0.875rem', sm: '1rem' },
                lineHeight: 1.5,
              }}
              dangerouslySetInnerHTML={{
                __html: part
                  .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
                  .replace(/\*(.*?)\*/g, '<em>$1</em>')
                  .replace(/`(.*?)`/g, '<code style="background: rgba(0,0,0,0.1); padding: 2px 4px; border-radius: 4px; font-family: monospace;">$1</code>')
              }}
            />
          );
        }
      })}
    </>
  );
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