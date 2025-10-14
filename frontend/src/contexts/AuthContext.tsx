import React, { createContext, useContext, useState, useEffect, ReactNode } from 'react';
import { apiService } from '../services/api';

interface User {
  username: string;
  email: string;
  accessToken: string;
  idToken: string;
  refreshToken: string;
  loginTime: number;
}

interface AuthContextType {
  user: User | null;
  login: (username: string, password: string) => Promise<boolean>;
  signup: (email: string, password: string) => Promise<boolean>;
  logout: () => void;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};

interface AuthProviderProps {
  children: ReactNode;
}

export const AuthProvider: React.FC<AuthProviderProps> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // Check for existing session on app load
    const storedUser = localStorage.getItem('devops-user');
    if (storedUser) {
      try {
        const userData = JSON.parse(storedUser);
        // Check if session is still valid (1 hour for JWT tokens)
        const sessionAge = Date.now() - userData.loginTime;
        const maxAge = 60 * 60 * 1000; // 1 hour
        
        if (sessionAge < maxAge) {
          // Verify token is still valid
          verifyToken(userData.accessToken).then(isValid => {
            if (isValid) {
              setUser(userData);
              // Set the token in API service for existing sessions
              apiService.setCognitoToken(userData.accessToken);
            } else {
              localStorage.removeItem('devops-user');
              apiService.clearAuthentication();
            }
            setIsLoading(false);
          });
        } else {
          localStorage.removeItem('devops-user');
          setIsLoading(false);
        }
      } catch (error) {
        console.error('Error loading user session:', error);
        localStorage.removeItem('devops-user');
        setIsLoading(false);
      }
    } else {
      setIsLoading(false);
    }
  }, []);

  const verifyToken = async (accessToken: string): Promise<boolean> => {
    try {
      const response = await fetch('http://localhost:3001/auth', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          action: 'verify',
          accessToken
        }),
      });

      const data = await response.json();
      return data.success;
    } catch (error) {
      console.error('Token verification failed:', error);
      return false;
    }
  };

  const login = async (username: string, password: string): Promise<boolean> => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await fetch('http://localhost:3001/auth', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          action: 'signin',
          username,
          password
        }),
      });

      const data = await response.json();

      if (data.success) {
        const userData: User = {
          username,
          email: username, // Cognito uses email as username
          accessToken: data.accessToken,
          idToken: data.idToken,
          refreshToken: data.refreshToken,
          loginTime: Date.now(),
        };
        
        setUser(userData);
        localStorage.setItem('devops-user', JSON.stringify(userData));
        
        // Set the Cognito token in API service
        apiService.setCognitoToken(data.accessToken);
        
        // Clear any existing session data to prevent 403 errors
        apiService.clearSessionData();
        
        setIsLoading(false);
        return true;
      } else {
        setError(data.error || 'Login failed');
        setIsLoading(false);
        return false;
      }
    } catch (error) {
      console.error('Login error:', error);
      setError('Network error. Please try again.');
      setIsLoading(false);
      return false;
    }
  };

  const signup = async (email: string, password: string): Promise<boolean> => {
    setIsLoading(true);
    setError(null);

    try {
      const response = await fetch('http://localhost:3001/auth', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          action: 'signup',
          username: email,
          email,
          password
        }),
      });

      const data = await response.json();

      if (data.success) {
        // After successful signup, automatically log in
        setIsLoading(false);
        return await login(email, password);
      } else {
        setError(data.error || 'Signup failed');
        setIsLoading(false);
        return false;
      }
    } catch (error) {
      console.error('Signup error:', error);
      setError('Network error. Please try again.');
      setIsLoading(false);
      return false;
    }
  };

  const logout = () => {
    setUser(null);
    setError(null);
    localStorage.removeItem('devops-user');
    
    // Clear authentication and session data from API service
    apiService.clearAuthentication();
  };

  const value: AuthContextType = {
    user,
    login,
    signup,
    logout,
    isAuthenticated: !!user,
    isLoading,
    error,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
};

export default AuthContext;