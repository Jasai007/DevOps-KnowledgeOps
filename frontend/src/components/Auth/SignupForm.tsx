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
  Link,
} from '@mui/material';
import {
  PersonAdd as SignupIcon,
  Person as PersonIcon,
} from '@mui/icons-material';

interface SignupFormProps {
  onSignup: (email: string, password: string) => Promise<boolean>;
  onBackToLogin: () => void;
  error?: string | null;
}

const SignupForm: React.FC<SignupFormProps> = ({ onSignup, onBackToLogin, error: authError }) => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setLocalError(null);

    // Validate passwords match
    if (password !== confirmPassword) {
      setLocalError('Passwords do not match');
      setLoading(false);
      return;
    }

    // Validate password strength
    if (password.length < 8) {
      setLocalError('Password must be at least 8 characters long');
      setLoading(false);
      return;
    }

    try {
      const success = await onSignup(email, password);
      if (!success) {
        // Error is handled by the auth context
      }
    } catch (err: any) {
      console.error('Signup error:', err);
    } finally {
      setLoading(false);
    }
  };

  const error = authError || localError;

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
              Create Account
            </Typography>
            <Typography variant="body2" color="text.secondary">
              Join DevOps AI Assistant
            </Typography>
          </Box>

          <form onSubmit={handleSubmit}>
            <TextField
              fullWidth
              label="Email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              margin="normal"
              required
              autoComplete="email"
              placeholder="your.email@company.com"
            />
            <TextField
              fullWidth
              label="Password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              margin="normal"
              required
              autoComplete="new-password"
              helperText="Minimum 8 characters"
            />
            <TextField
              fullWidth
              label="Confirm Password"
              type="password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              margin="normal"
              required
              autoComplete="new-password"
            />

            {error && (
              <Alert severity="error" sx={{ mt: 2 }}>
                {error}
              </Alert>
            )}

            <Button
              type="submit"
              fullWidth
              variant="contained"
              disabled={loading}
              startIcon={loading ? <CircularProgress size={20} /> : <SignupIcon />}
              sx={{ mt: 3, mb: 2 }}
            >
              {loading ? 'Creating Account...' : 'Create Account'}
            </Button>
          </form>

          <Box sx={{ textAlign: 'center', mt: 2 }}>
            <Typography variant="body2" color="text.secondary">
              Already have an account?{' '}
              <Link
                component="button"
                variant="body2"
                onClick={onBackToLogin}
                sx={{ cursor: 'pointer' }}
              >
                Sign In
              </Link>
            </Typography>
          </Box>
        </CardContent>
      </Card>
    </Box>
  );
};

export default SignupForm;