import React, { useState, useEffect } from 'react';
import {
  Box,
  Drawer,
  List,
  ListItem,
  ListItemButton,
  ListItemText,
  ListItemIcon,
  Typography,
  IconButton,
  Divider,
  Chip,
  Tooltip,
  useTheme,
  useMediaQuery,
} from '@mui/material';
import {
  Chat as ChatIcon,
  Delete as DeleteIcon,
  History as HistoryIcon,
  Close as CloseIcon,
  Add as AddIcon,
} from '@mui/icons-material';
import { apiService } from '../../services/api';

interface ChatSession {
  sessionId: string;
  createdAt: string;
  lastActivity: string;
  messageCount: number;
  preview?: string;
}

interface ChatHistoryProps {
  open: boolean;
  onClose: () => void;
  currentSessionId?: string;
  onSessionSelect: (sessionId: string) => void;
  onNewChat: () => void;
  refreshTrigger?: number;
}

const ChatHistory: React.FC<ChatHistoryProps> = ({
  open,
  onClose,
  currentSessionId,
  onSessionSelect,
  onNewChat,
  refreshTrigger,
}) => {
  const [sessions, setSessions] = useState<ChatSession[]>([]);
  const [loading, setLoading] = useState(false);
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));

  useEffect(() => {
    if (open) {
      loadChatHistory();
    }
  }, [open]);

  // Refresh chat history when refreshTrigger changes (new session created or message sent)
  useEffect(() => {
    if (open && refreshTrigger !== undefined) {
      // Delay refresh to allow backend to update
      const timer = setTimeout(() => {
        loadChatHistory();
      }, 500);
      return () => clearTimeout(timer);
    }
  }, [refreshTrigger, open]);

  const loadChatHistory = async () => {
    setLoading(true);
    try {
      const response = await apiService.getUserSessions();
      if (response.success && response.sessions) {
        // Automatically filter out empty sessions and delete them
        const allSessions = response.sessions;
        const emptySessions = allSessions.filter(session => session.messageCount === 0);
        const nonEmptySessions = allSessions.filter(session => session.messageCount > 0);

        // Delete empty sessions automatically in the background
        if (emptySessions.length > 0) {
          console.log(`Auto-deleting ${emptySessions.length} empty sessions`);
          emptySessions.forEach(session => {
            apiService.deleteSession(session.sessionId).catch(error => {
              console.error(`Failed to delete empty session ${session.sessionId}:`, error);
            });
          });
        }

        // Only show sessions with messages
        setSessions(nonEmptySessions);
      }
    } catch (error) {
      console.error('Failed to load chat history:', error);
    } finally {
      setLoading(false);
    }
  };



  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const sessionDate = new Date(date.getFullYear(), date.getMonth(), date.getDate());
    const diffTime = today.getTime() - sessionDate.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Yesterday';
    if (diffDays <= 7) return `${diffDays} days ago`;
    if (diffDays <= 30) return `${Math.floor(diffDays / 7)} week${Math.floor(diffDays / 7) > 1 ? 's' : ''} ago`;
    return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  };

  const getSessionPreview = (session: ChatSession) => {
    if (session.preview && session.preview.trim()) {
      // Truncate long previews and clean them up
      const cleanPreview = session.preview.trim().replace(/\n/g, ' ');
      return cleanPreview.length > 50 ? `${cleanPreview.substring(0, 50)}...` : cleanPreview;
    }
    // Fallback to a more descriptive format
    return `Chat session (${session.messageCount} message${session.messageCount !== 1 ? 's' : ''})`;
  };

  const handleSessionClick = (sessionId: string) => {
    onSessionSelect(sessionId);
    if (isMobile) {
      onClose();
    }
  };

  const handleNewChat = () => {
    onNewChat();
    if (isMobile) {
      onClose();
    }
  };

  const handleDeleteSession = async (sessionId: string, e: React.MouseEvent) => {
    e.stopPropagation();

    try {
      const response = await apiService.deleteSession(sessionId);
      if (response.success) {
        // Remove session from local state
        setSessions(prev => prev.filter(s => s.sessionId !== sessionId));

        // If this was the current session, trigger new chat
        if (sessionId === currentSessionId) {
          onNewChat();
        }

        console.log('Session deleted successfully');
      } else {
        console.error('Failed to delete session:', response.error);
      }
    } catch (error) {
      console.error('Error deleting session:', error);
    }
  };

  const drawerWidth = 320;

  return (
    <Drawer
      anchor="left"
      open={open}
      onClose={onClose}
      variant={isMobile ? 'temporary' : 'persistent'}
      sx={{
        width: drawerWidth,
        flexShrink: 0,
        '& .MuiDrawer-paper': {
          width: drawerWidth,
          boxSizing: 'border-box',
          bgcolor: 'background.paper',
          borderRight: 1,
          borderColor: 'divider',
        },
      }}
    >
      {/* Header */}
      <Box sx={{
        p: 2,
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        borderBottom: 1,
        borderColor: 'divider',
      }}>
        <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
          <HistoryIcon color="primary" />
          <Typography variant="h6" component="h2">
            Chat History
          </Typography>
        </Box>
        <IconButton onClick={onClose} size="small">
          <CloseIcon />
        </IconButton>
      </Box>

      {/* New Chat Button */}
      <Box sx={{ p: 2 }}>
        <ListItemButton
          onClick={handleNewChat}
          sx={{
            borderRadius: 2,
            border: 1,
            borderColor: 'primary.main',
            borderStyle: 'dashed',
            '&:hover': {
              bgcolor: 'primary.50',
              borderStyle: 'solid',
            },
          }}
        >
          <ListItemIcon>
            <AddIcon color="primary" />
          </ListItemIcon>
          <ListItemText
            primary="New Chat"
            primaryTypographyProps={{
              color: 'primary.main',
              fontWeight: 'medium',
            }}
          />
        </ListItemButton>
      </Box>

      <Divider />

      {/* Chat Sessions List */}
      <Box sx={{ flex: 1, overflow: 'auto' }}>
        {loading ? (
          <Box sx={{ p: 2, textAlign: 'center' }}>
            <Typography color="text.secondary">
              Loading chat history...
            </Typography>
          </Box>
        ) : sessions.length === 0 ? (
          <Box sx={{ p: 2, textAlign: 'center' }}>
            <Typography color="text.secondary" variant="body2">
              No previous conversations
            </Typography>
            <Typography color="text.secondary" variant="caption">
              Start a new chat to begin!
            </Typography>
          </Box>
        ) : (
          <List sx={{ p: 1 }}>
            {sessions.map((session) => (
              <ListItem key={session.sessionId} disablePadding sx={{ mb: 1 }}>
                <ListItemButton
                  onClick={() => handleSessionClick(session.sessionId)}
                  selected={session.sessionId === currentSessionId}
                  sx={{
                    borderRadius: 2,
                    '&.Mui-selected': {
                      bgcolor: 'primary.50',
                      '&:hover': {
                        bgcolor: 'primary.100',
                      },
                    },
                  }}
                >
                  <ListItemIcon>
                    <ChatIcon
                      color={session.sessionId === currentSessionId ? 'primary' : 'inherit'}
                    />
                  </ListItemIcon>
                  <ListItemText
                    primary={
                      <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <Typography
                          variant="body1"
                          sx={{
                            fontWeight: session.sessionId === currentSessionId ? 600 : 500,
                            fontSize: '0.95rem',
                            flex: 1,
                            overflow: 'hidden',
                            textOverflow: 'ellipsis',
                            whiteSpace: 'nowrap',
                            color: 'text.primary',
                          }}
                        >
                          {getSessionPreview(session)}
                        </Typography>
                        <Chip
                          label={session.messageCount}
                          size="small"
                          variant="outlined"
                          sx={{ minWidth: 'auto', height: 20 }}
                        />
                      </Box>
                    }
                    secondary={
                      <Typography
                        variant="caption"
                        color="text.secondary"
                        sx={{
                          fontSize: '0.75rem',
                          overflow: 'hidden',
                          textOverflow: 'ellipsis',
                          whiteSpace: 'nowrap',
                          display: 'block',
                          mt: 0.25,
                        }}
                      >
                        {formatDate(session.lastActivity)}
                      </Typography>
                    }
                  />
                  <Tooltip title="Delete conversation">
                    <IconButton
                      size="small"
                      onClick={(e) => handleDeleteSession(session.sessionId, e)}
                      sx={{
                        opacity: 0.6,
                        '&:hover': { opacity: 1 },
                      }}
                    >
                      <DeleteIcon fontSize="small" />
                    </IconButton>
                  </Tooltip>
                </ListItemButton>
              </ListItem>
            ))}
          </List>
        )}
      </Box>

      {/* Footer */}
      <Box sx={{
        p: 2,
        borderTop: 1,
        borderColor: 'divider',
        bgcolor: 'background.default',
      }}>
        <Typography variant="caption" color="text.secondary" align="center" display="block">
          {sessions.length} conversation{sessions.length !== 1 ? 's' : ''}
        </Typography>
      </Box>
    </Drawer>
  );
};

export default ChatHistory;