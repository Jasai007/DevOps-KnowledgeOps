import React, { useState, useEffect } from 'react';
import {
  Box,
  Button,
  Card,
  CardContent,
  Typography,
  Alert,
  Divider,
  List,
  ListItem,
  ListItemText,
  Chip,
  Grid,
  Paper,
} from '@mui/material';
import {
  Refresh as RefreshIcon,
  BugReport as BugIcon,
  CheckCircle as CheckIcon,
  Error as ErrorIcon,
  Login as LoginIcon,
} from '@mui/icons-material';
import { apiService } from '../../services/api';
import { useAuth } from '../../contexts/AuthContext';

interface DebugInfo {
  userId: string;
  totalSessions: number;
  userSessionCount: number;
  userSessions: string[];
  sessionDetails: any[];
}

interface TestResult {
  test: string;
  status: 'pass' | 'fail' | 'warning';
  message: string;
  details?: any;
}

const ChatHistoryDebug: React.FC = () => {
  const [debugInfo, setDebugInfo] = useState<DebugInfo | null>(null);
  const [testResults, setTestResults] = useState<TestResult[]>([]);
  const [loading, setLoading] = useState(false);
  const { user, isAuthenticated, login } = useAuth();
  const [testCredentials, setTestCredentials] = useState({
    email: 'debug@example.com',
    password: 'DebugPassword123!'
  });

  const createTestUser = async () => {
    setLoading(true);
    try {
      // Try to create test user via backend signup
      const response = await fetch('http://localhost:3001/auth', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          action: 'signup',
          username: testCredentials.email,
          email: testCredentials.email,
          password: testCredentials.password
        })
      });

      const data = await response.json();

      if (data.success) {
        addTestResult('User Creation', 'pass', 'Test user created successfully');
        // Automatically try to sign in
        setTimeout(() => authenticateTestUser(), 1000);
      } else {
        if (data.error.includes('already exists')) {
          addTestResult('User Creation', 'warning', 'Test user already exists, trying to sign in...');
          setTimeout(() => authenticateTestUser(), 500);
        } else {
          addTestResult('User Creation', 'fail', `Failed to create test user: ${data.error}`);
        }
      }
    } catch (error) {
      addTestResult('User Creation', 'fail', `Error creating test user: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  const authenticateTestUser = async () => {
    setLoading(true);
    try {
      // Try to sign in with test credentials
      const success = await login(testCredentials.email, testCredentials.password);
      if (success) {
        addTestResult('Authentication', 'pass', 'Cognito authentication successful');
      } else {
        addTestResult('Authentication', 'fail', 'Cognito authentication failed - user may not exist');

        // Provide instructions for creating test user
        addTestResult('Authentication', 'warning', 'To use debug mode, create a test user via the signup form or AWS Cognito console');
      }
    } catch (error) {
      addTestResult('Authentication', 'fail', `Authentication error: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  const addTestResult = (test: string, status: 'pass' | 'fail' | 'warning', message: string, details?: any) => {
    setTestResults(prev => [...prev, { test, status, message, details }]);
  };

  const runDiagnostics = async () => {
    setLoading(true);
    setTestResults([]);

    try {
      // Test 1: Check authentication
      if (!isAuthenticated) {
        addTestResult('Authentication', 'fail', 'Not authenticated - please authenticate first');
        setLoading(false);
        return;
      }
      addTestResult('Authentication', 'pass', 'User is authenticated');

      // Test 2: Get debug info
      try {
        const debug = await apiService.getDebugInfo();
        setDebugInfo(debug);
        addTestResult('Debug Info', 'pass', 'Debug endpoint accessible', debug);
      } catch (error) {
        addTestResult('Debug Info', 'fail', `Debug endpoint failed: ${error}`);
      }

      // Test 3: Create session
      try {
        const sessionResult = await apiService.createSession();
        if (sessionResult.success) {
          addTestResult('Session Creation', 'pass', `Session created: ${sessionResult.session?.sessionId}`);
        } else {
          addTestResult('Session Creation', 'fail', `Session creation failed: ${sessionResult.error}`);
        }
      } catch (error) {
        addTestResult('Session Creation', 'fail', `Session creation error: ${error}`);
      }

      // Test 4: Get user sessions
      try {
        const sessionsResult = await apiService.getUserSessions();
        if (sessionsResult.success) {
          const sessionCount = sessionsResult.sessions?.length || 0;
          if (sessionCount > 0) {
            addTestResult('Session List', 'pass', `Found ${sessionCount} user sessions`);
          } else {
            addTestResult('Session List', 'warning', 'No user sessions found - this might indicate a session association issue');
          }
        } else {
          addTestResult('Session List', 'fail', `Failed to get sessions: ${sessionsResult.error}`);
        }
      } catch (error) {
        addTestResult('Session List', 'fail', `Session list error: ${error}`);
      }

      // Test 5: Send test message
      try {
        const messageResult = await apiService.sendMessage('Test message for chat history debugging');
        if (messageResult.success) {
          addTestResult('Message Sending', 'pass', `Message sent successfully, session: ${messageResult.sessionId}`);
        } else {
          addTestResult('Message Sending', 'fail', `Message sending failed: ${messageResult.error}`);
        }
      } catch (error) {
        addTestResult('Message Sending', 'fail', `Message sending error: ${error}`);
      }

      // Test 6: Get updated debug info
      try {
        const updatedDebug = await apiService.getDebugInfo();
        setDebugInfo(updatedDebug);
        addTestResult('Updated Debug Info', 'pass', 'Debug info refreshed after tests');
      } catch (error) {
        addTestResult('Updated Debug Info', 'fail', `Failed to refresh debug info: ${error}`);
      }

    } catch (error) {
      addTestResult('General Error', 'fail', `Unexpected error: ${error}`);
    } finally {
      setLoading(false);
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pass': return <CheckIcon color="success" />;
      case 'fail': return <ErrorIcon color="error" />;
      case 'warning': return <ErrorIcon color="warning" />;
      default: return <BugIcon />;
    }
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pass': return 'success';
      case 'fail': return 'error';
      case 'warning': return 'warning';
      default: return 'default';
    }
  };

  return (
    <Box sx={{ p: 3, maxWidth: 1200, mx: 'auto' }}>
      <Typography variant="h4" gutterBottom sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
        <BugIcon color="primary" />
        Chat History Debug Tool
      </Typography>

      <Alert severity="info" sx={{ mb: 3 }}>
        This tool helps diagnose and fix chat history issues with Cognito authentication.
        Run diagnostics to check session management, user authentication, and message storage.
        <br /><strong>Note:</strong> Now uses AWS Cognito for proper user management and session isolation.
      </Alert>

      {/* Authentication Section */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>Authentication Status</Typography>
          <Box sx={{ display: 'flex', alignItems: 'center', gap: 2, flexWrap: 'wrap' }}>
            <Chip
              label={isAuthenticated ? `Authenticated (${user?.email})` : 'Not Authenticated'}
              color={isAuthenticated ? 'success' : 'error'}
              icon={getStatusIcon(isAuthenticated ? 'pass' : 'fail')}
            />
            {isAuthenticated && (
              <Chip
                label={`User ID: ${user?.username || 'N/A'}`}
                variant="outlined"
                size="small"
              />
            )}
          </Box>

          {!isAuthenticated && (
            <Box sx={{ mt: 2 }}>
              <Alert severity="info" sx={{ mb: 2 }}>
                Debug mode requires Cognito authentication. You can either:
                <br />• Sign in through the main app login form
                <br />• Use the test authentication below (requires existing test user)
              </Alert>
              <Box sx={{ display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                <Button
                  variant="contained"
                  startIcon={<LoginIcon />}
                  onClick={authenticateTestUser}
                  disabled={loading}
                >
                  {loading ? 'Authenticating...' : 'Sign In Test User'}
                </Button>
                <Button
                  variant="outlined"
                  onClick={createTestUser}
                  disabled={loading}
                >
                  Create Test User
                </Button>
              </Box>
              <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
                Test credentials: {testCredentials.email} / {testCredentials.password}
              </Typography>
            </Box>
          )}
        </CardContent>
      </Card>

      {/* Controls */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Typography variant="h6" gutterBottom>Diagnostics</Typography>
          <Button
            variant="contained"
            startIcon={<RefreshIcon />}
            onClick={runDiagnostics}
            disabled={loading || !isAuthenticated}
            sx={{ mr: 2 }}
          >
            {loading ? 'Running Diagnostics...' : 'Run Full Diagnostics'}
          </Button>
          <Button
            variant="outlined"
            onClick={() => setTestResults([])}
            disabled={loading}
          >
            Clear Results
          </Button>
        </CardContent>
      </Card>

      <Grid container spacing={3}>
        {/* Test Results */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>Test Results</Typography>
              {testResults.length === 0 ? (
                <Typography color="text.secondary">
                  No tests run yet. Click "Run Full Diagnostics" to start.
                </Typography>
              ) : (
                <List>
                  {testResults.map((result, index) => (
                    <ListItem key={index} divider>
                      <ListItemText
                        primary={
                          <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                            {getStatusIcon(result.status)}
                            <Typography variant="subtitle2">{result.test}</Typography>
                            <Chip
                              label={result.status.toUpperCase()}
                              size="small"
                              color={getStatusColor(result.status) as any}
                            />
                          </Box>
                        }
                        secondary={result.message}
                      />
                    </ListItem>
                  ))}
                </List>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Debug Information */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>Debug Information</Typography>
              {debugInfo ? (
                <Box>
                  <Paper sx={{ p: 2, bgcolor: 'grey.50' }}>
                    <Typography variant="body2" component="pre" sx={{ fontFamily: 'monospace' }}>
                      {JSON.stringify(debugInfo, null, 2)}
                    </Typography>
                  </Paper>

                  <Divider sx={{ my: 2 }} />

                  <Typography variant="subtitle2" gutterBottom>Analysis:</Typography>
                  <List dense>
                    <ListItem>
                      <ListItemText
                        primary="User ID"
                        secondary={debugInfo.userId || 'Not available'}
                      />
                    </ListItem>
                    <ListItem>
                      <ListItemText
                        primary="Total Sessions"
                        secondary={debugInfo.totalSessions || 0}
                      />
                    </ListItem>
                    <ListItem>
                      <ListItemText
                        primary="User Sessions"
                        secondary={debugInfo.userSessionCount || 0}
                      />
                    </ListItem>
                    {debugInfo.userSessionCount === 0 && debugInfo.totalSessions > 0 && (
                      <Alert severity="warning" sx={{ mt: 1 }}>
                        Sessions exist but are not associated with this Cognito user. This could indicate:
                        <br />• Sessions from other users (normal with Cognito isolation)
                        <br />• Old demo sessions (expected after Cognito migration)
                        <br />• Session association issue (check backend logs)
                      </Alert>
                    )}
                  </List>
                </Box>
              ) : (
                <Typography color="text.secondary">
                  No debug information available. Run diagnostics to fetch data.
                </Typography>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Recommendations */}
      {testResults.some(r => r.status === 'fail' || r.status === 'warning') && (
        <Card sx={{ mt: 3 }}>
          <CardContent>
            <Typography variant="h6" gutterBottom color="warning.main">
              Recommendations
            </Typography>
            <List>
              {testResults.filter(r => r.status === 'fail').length > 0 && (
                <ListItem>
                  <ListItemText
                    primary="Critical Issues Found"
                    secondary="Some tests failed. Check the backend server logs and ensure all endpoints are working correctly."
                  />
                </ListItem>
              )}
              {debugInfo && debugInfo.userSessionCount === 0 && debugInfo.totalSessions > 0 && (
                <ListItem>
                  <ListItemText
                    primary="Session Isolation Working"
                    secondary="Sessions exist but belong to other Cognito users. This is expected behavior with proper user isolation. Create new sessions to see them appear for this user."
                  />
                </ListItem>
              )}
              <ListItem>
                <ListItemText
                  primary="Cognito Authentication Active"
                  secondary="The app now uses AWS Cognito for authentication. Each user has isolated sessions based on their unique Cognito user ID."
                />
              </ListItem>
            </List>
          </CardContent>
        </Card>
      )}
    </Box>
  );
};

export default ChatHistoryDebug;