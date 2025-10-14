import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  TextField,
  Button,
  Typography,
  Alert,
  CircularProgress,
  Divider,
  Chip,
  Link,
} from '@mui/material';
import {
  Login as LoginIcon,
  Person as PersonIcon,
} from '@mui/icons-material';

interface LoginFormProps {
  onLogin: (username: string, password: string) => Promise<boolean>;
  onShowSignup?: () => void;
  error?: string | null;
}

const LoginForm: React.FC<LoginFormProps> = ({ onLogin, onShowSignup, error: authError }) => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);

  const demoUsers = [
    { username: 'demo@example.com', password: 'Demo123!', role: 'Demo User' },
    { username: 'admin@example.com', password: 'Admin123!', role: 'Administrator' },
    { username: 'user1@example.com', password: 'User123!', role: 'Regular User' },
  ];

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    try {
      const success = await onLogin(username, password);
      if (!success) {
        // Error is handled by the auth context
      }
    } catch (err: any) {
      console.error('Login error:', err);
    } finally {
      setLoading(false);
    }
  };

  const handleDemoLogin = (demoUser: typeof demoUsers[0]) => {
    setUsername(demoUser.username);
    setPassword(demoUser.password);
  };

  return (
    <Box
      sx={{
        minHeight: '100vh',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        bgcolor: 'grey.50',
        p: 2,
      }}
    >
      <Card sx={{ maxWidth: 400, width: '100%' }}>
        <CardContent sx={{ p: 4 }}>
          <Box sx={{ textAlign: 'center', mb: 3 }}>
            <PersonIcon sx={{ fontSize: 48, color: 'primary.main', mb: 1 }} />
            <Typography variant="h4" component="h1" gutterBottom>
              DevOps AI Assistant
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Sign in to access your personal chat history
            </Typography>
          </Box>

          <form onSubmit={handleSubmit}>
            <TextField
              fullWidth
              label="Email"
              type="email"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              margin="normal"
              required
              autoComplete="email"
              placeholder="demo@example.com"
            />
            <TextField
              fullWidth
              label="Password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              margin="normal"
              required
              autoComplete="current-password"
            />

            {authError && (
              <Alert severity="error" sx={{ mt: 2 }}>
                {authError}
              </Alert>
            )}

            <Button
              type="submit"
              fullWidth
              variant="contained"
              disabled={loading}
              startIcon={loading ? <CircularProgress size={20} /> : <LoginIcon />}
              sx={{ mt: 3, mb: 2 }}
            >
              {loading ? 'Signing In...' : 'Sign In'}
            </Button>
          </form>

          {onShowSignup && (
            <Box sx={{ textAlign: 'center', mt: 2 }}>
              <Typography variant="body2" color="text.secondary">
                Don't have an account?{' '}
                <Link
                  component="button"
                  variant="body2"
                  onClick={onShowSignup}
                  sx={{ cursor: 'pointer' }}
                >
                  Create Account
                </Link>
              </Typography>
            </Box>
          )}

          <Divider sx={{ my: 2 }}>
            <Typography variant="caption" color="text.secondary">
              Demo Accounts
            </Typography>
          </Divider>

          <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1 }}>
            {demoUsers.map((user) => (
              <Chip
                key={user.username}
                label={`${user.username} (${user.role})`}
                variant="outlined"
                clickable
                onClick={() => handleDemoLogin(user)}
                sx={{ justifyContent: 'flex-start' }}
              />
            ))}
          </Box>

          <Typography variant="caption" color="text.secondary" sx={{ mt: 2, display: 'block', textAlign: 'center' }}>
            Click any demo account above to auto-fill credentials
          </Typography>
        </CardContent>
      </Card>
    </Box>
  );
};

export default LoginForm;