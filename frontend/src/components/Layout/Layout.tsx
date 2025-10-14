import React, { useState } from 'react';
import {
  Box,
  useTheme,
  useMediaQuery,
} from '@mui/material';
import Header from '../Header/Header';
import ChatHistory from '../Chat/ChatHistory';

interface LayoutProps {
  children: React.ReactNode;
  onSessionSelect?: (sessionId: string) => void;
  onNewChat?: () => void;
  currentSessionId?: string;
  refreshTrigger?: number;
}

const Layout: React.FC<LayoutProps> = ({ 
  children, 
  onSessionSelect, 
  onNewChat, 
  currentSessionId,
  refreshTrigger
}) => {
  const [chatHistoryOpen, setChatHistoryOpen] = useState(false);
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));

  const handleChatHistoryToggle = () => {
    setChatHistoryOpen(!chatHistoryOpen);
  };

  return (
    <Box sx={{ 
      height: '100vh', 
      display: 'flex', 
      flexDirection: 'column',
      bgcolor: 'grey.50',
      overflow: 'hidden',
    }}>
      <Header 
        onHistoryClick={handleChatHistoryToggle}
      />

      <ChatHistory
        open={chatHistoryOpen}
        onClose={() => setChatHistoryOpen(false)}
        currentSessionId={currentSessionId}
        onSessionSelect={onSessionSelect || (() => {})}
        onNewChat={onNewChat || (() => {})}
        refreshTrigger={refreshTrigger}
      />
      
      <Box sx={{ 
        flex: 1,
        display: 'flex',
        flexDirection: 'column',
        overflow: 'hidden',
        marginLeft: chatHistoryOpen && !isMobile ? '320px' : 0,
        transition: theme.transitions.create('margin-left', {
          easing: theme.transitions.easing.sharp,
          duration: theme.transitions.duration.leavingScreen,
        }),
      }}>
        {children}
      </Box>
    </Box>
  );
};

export default Layout;