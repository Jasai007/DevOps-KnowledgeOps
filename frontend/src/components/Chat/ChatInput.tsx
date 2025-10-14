import React, { useState } from 'react';
import {
  Box,
  TextField,
  IconButton,
  Paper,
  CircularProgress,
  useTheme,
  useMediaQuery,
  Fab,
} from '@mui/material';
import {
  Send as SendIcon,
  Mic as MicIcon,
  AttachFile as AttachIcon,
} from '@mui/icons-material';

interface ChatInputProps {
  onSendMessage: (message: string) => void;
  isLoading: boolean;
  disabled?: boolean;
}

const ChatInput: React.FC<ChatInputProps> = ({ 
  onSendMessage, 
  isLoading, 
  disabled = false 
}) => {
  const [inputValue, setInputValue] = useState('');
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));

  const handleSend = () => {
    const message = inputValue.trim();
    if (message && !isLoading && !disabled) {
      onSendMessage(message);
      setInputValue('');
    }
  };

  const handleKeyPress = (event: React.KeyboardEvent) => {
    if (event.key === 'Enter' && !event.shiftKey) {
      event.preventDefault();
      handleSend();
    }
  };

  const canSend = inputValue.trim() && !isLoading && !disabled;

  if (isMobile) {
    return (
      <Box
        sx={{
          position: 'fixed',
          bottom: 0,
          left: 0,
          right: 0,
          p: 1,
          bgcolor: 'background.paper',
          borderTop: 1,
          borderColor: 'divider',
          zIndex: 1000,
        }}
      >
        <Paper elevation={3} sx={{ borderRadius: 3 }}>
          <Box sx={{ display: 'flex', alignItems: 'flex-end', p: 1 }}>
            <TextField
              fullWidth
              multiline
              maxRows={4}
              value={inputValue}
              onChange={(e) => setInputValue(e.target.value)}
              onKeyPress={handleKeyPress}
              placeholder="Ask me anything about DevOps..."
              variant="outlined"
              disabled={disabled}
              size="small"
              sx={{
                '& .MuiOutlinedInput-root': {
                  borderRadius: 2,
                  '& fieldset': {
                    border: 'none',
                  },
                },
                '& .MuiInputBase-input': {
                  fontSize: '0.9rem',
                },
              }}
            />
            
            <Box sx={{ display: 'flex', gap: 0.5, ml: 1 }}>
              <IconButton
                size="small"
                color="primary"
                disabled
                sx={{ opacity: 0.5 }}
              >
                <AttachIcon fontSize="small" />
              </IconButton>
              
              <IconButton
                size="small"
                color="primary"
                disabled
                sx={{ opacity: 0.5 }}
              >
                <MicIcon fontSize="small" />
              </IconButton>
            </Box>
          </Box>
        </Paper>
        
        <Fab
          color="primary"
          size="medium"
          onClick={handleSend}
          disabled={!canSend}
          sx={{
            position: 'absolute',
            bottom: 16,
            right: 16,
            zIndex: 1001,
          }}
        >
          {isLoading ? <CircularProgress size={24} color="inherit" /> : <SendIcon />}
        </Fab>
      </Box>
    );
  }

  return (
    <Paper 
      elevation={2} 
      sx={{ 
        p: 2,
        position: 'sticky',
        bottom: 0,
        bgcolor: 'background.paper',
        borderRadius: 2,
      }}
    >
      <Box sx={{ display: 'flex', gap: 1, alignItems: 'flex-end' }}>
        <TextField
          fullWidth
          multiline
          maxRows={4}
          value={inputValue}
          onChange={(e) => setInputValue(e.target.value)}
          onKeyPress={handleKeyPress}
          placeholder="Ask me anything about DevOps..."
          variant="outlined"
          disabled={disabled}
          sx={{
            '& .MuiOutlinedInput-root': {
              borderRadius: 2,
            },
          }}
        />
        
        <IconButton
          color="primary"
          onClick={handleSend}
          disabled={!canSend}
          sx={{
            minWidth: 56,
            height: 56,
            borderRadius: 2,
            bgcolor: canSend ? 'primary.main' : 'grey.300',
            color: 'white',
            '&:hover': {
              bgcolor: canSend ? 'primary.dark' : 'grey.300',
            },
            '&:disabled': {
              bgcolor: 'grey.300',
              color: 'grey.500',
            },
          }}
        >
          {isLoading ? <CircularProgress size={24} color="inherit" /> : <SendIcon />}
        </IconButton>
      </Box>
    </Paper>
  );
};

export default ChatInput;