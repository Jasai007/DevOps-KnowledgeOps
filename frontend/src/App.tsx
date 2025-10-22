import React, { useState } from 'react';
import { Box, Tabs, Tab, CircularProgress, Typography } from '@mui/material';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import LoginForm from './components/Auth/LoginForm';
import SignupForm from './components/Auth/SignupForm';
import Layout from './components/Layout/Layout';
import ChatContainer from './components/Chat/ChatContainer';
import './App.css';

const AppContent: React.FC = () => {
  const { isAuthenticated, isLoading, login, signup, error } = useAuth();
  const [currentSessionId, setCurrentSessionId] = useState<string | undefined>();
  const [debugMode, setDebugMode] = useState(false);
  const [showSignup, setShowSignup] = useState(false);
  const [refreshTrigger, setRefreshTrigger] = useState(0);

  const handleSessionSelect = (sessionId: string) => {
    setCurrentSessionId(sessionId);
  };

  const handleNewChat = () => {
    setCurrentSessionId(undefined);
    setRefreshTrigger(prev => prev + 1);
  };

  const handleNewMessage = () => {
    setRefreshTrigger(prev => prev + 1);
  };

  // Check if we're in debug mode (add ?debug=true to URL)
  React.useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    setDebugMode(urlParams.get('debug') === 'true');
  }, []);

  if (isLoading) {
    return (
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          minHeight: '100vh',
          flexDirection: 'column',
          gap: 2,
        }}
      >
        <CircularProgress />
        <Typography variant="body2" color="text.secondary">
          Loading...
        </Typography>
      </Box>
    );
  }

  if (!isAuthenticated) {
    if (showSignup) {
      return (
        <SignupForm 
          onSignup={signup} 
          onBackToLogin={() => setShowSignup(false)}
          error={error} 
        />
      );
    }
    return (
      <LoginForm 
        onLogin={login} 
        onShowSignup={() => setShowSignup(true)}
        error={error} 
      />
    );
  }


  return (
    <Layout
      currentSessionId={currentSessionId}
      onSessionSelect={handleSessionSelect}
      onNewChat={handleNewChat}
      refreshTrigger={refreshTrigger}
    >
      <ChatContainer
        sessionId={currentSessionId}
        onSessionChange={setCurrentSessionId}
        onNewMessage={handleNewMessage}
      />
    </Layout>
  );
};

function App() {
  return (
    <AuthProvider>
      <AppContent />
    </AuthProvider>
  );
}

export default App;