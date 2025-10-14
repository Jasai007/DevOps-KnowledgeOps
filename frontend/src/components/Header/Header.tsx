import React, { useState } from 'react';
import {
  AppBar,
  Toolbar,
  Typography,
  Avatar,
  Chip,
  Box,
  IconButton,
  useTheme,
  useMediaQuery,
  Menu,
  MenuItem,
  ListItemIcon,
  ListItemText,
  Divider,
} from '@mui/material';
import {
  SmartToy as BotIcon,
  History as HistoryIcon,
  AccountCircle as AccountIcon,
  Logout as LogoutIcon,
  Person as PersonIcon,
} from '@mui/icons-material';
import { useAuth } from '../../contexts/AuthContext';

interface HeaderProps {
  onHistoryClick?: () => void;
}

const Header: React.FC<HeaderProps> = ({ onHistoryClick }) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const { user, logout } = useAuth();
  const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);

  const handleUserMenuClick = (event: React.MouseEvent<HTMLElement>) => {
    setAnchorEl(event.currentTarget);
  };

  const handleUserMenuClose = () => {
    setAnchorEl(null);
  };

  const handleLogout = () => {
    logout();
    handleUserMenuClose();
  };

  return (
    <AppBar
      position="sticky"
      elevation={2}
      sx={{
        background: 'linear-gradient(135deg, #1976d2 0%, #1565c0 100%)',
        color: 'white',
      }}
    >
      <Toolbar sx={{ px: { xs: 1, sm: 2 } }}>

        <Avatar
          sx={{
            bgcolor: 'primary.dark',
            mr: { xs: 1, sm: 2 },
            width: { xs: 32, sm: 40 },
            height: { xs: 32, sm: 40 },
          }}
        >
          <BotIcon fontSize={isMobile ? 'small' : 'medium'} />
        </Avatar>

        <Box sx={{ flexGrow: 1 }}>
          <Typography
            variant={isMobile ? 'h6' : 'h5'}
            component="h1"
            sx={{
              fontWeight: 600,
              fontSize: { xs: '1.1rem', sm: '1.25rem', md: '1.5rem' }
            }}
          >
            DevOps KnowledgeOps Agent
          </Typography>
          <Typography
            variant="body2"
            sx={{
              opacity: 0.9,
              fontSize: { xs: '0.75rem', sm: '0.875rem' },
              display: { xs: 'none', sm: 'block' }
            }}
          >
            Powered by Amazon Bedrock AgentCore
          </Typography>
        </Box>

        <Box sx={{
          display: 'flex',
          alignItems: 'center',
          gap: { xs: 0.5, sm: 1 },
        }}>
          {onHistoryClick && (
            <IconButton
              color="inherit"
              onClick={onHistoryClick}
              sx={{ mr: 1 }}
            >
              <HistoryIcon />
            </IconButton>
          )}

          <Box sx={{
            display: 'flex',
            gap: { xs: 0.5, sm: 1 },
            flexWrap: 'wrap',
            alignItems: 'center',
          }}>
            <Chip
              label="AgentCore"
              size="small"
              variant="outlined"
              sx={{
                color: 'white',
                borderColor: 'white',
                fontSize: { xs: '0.7rem', sm: '0.75rem' },
                height: { xs: 24, sm: 32 }
              }}
            />

            <Chip
              label="Authenticated"
              size="small"
              sx={{
                bgcolor: 'success.main',
                color: 'white',
                fontSize: { xs: '0.7rem', sm: '0.75rem' },
                height: { xs: 24, sm: 32 }
              }}
            />

            {/* User Menu */}
            <IconButton
              color="inherit"
              onClick={handleUserMenuClick}
              sx={{ ml: 1 }}
            >
              <AccountIcon />
            </IconButton>

            <Menu
              anchorEl={anchorEl}
              open={Boolean(anchorEl)}
              onClose={handleUserMenuClose}
              anchorOrigin={{
                vertical: 'bottom',
                horizontal: 'right',
              }}
              transformOrigin={{
                vertical: 'top',
                horizontal: 'right',
              }}
            >
              <MenuItem disabled>
                <ListItemIcon>
                  <PersonIcon fontSize="small" />
                </ListItemIcon>
                <ListItemText
                  primary={user?.email || 'User'}
                  secondary="Authenticated"
                />
              </MenuItem>
              <Divider />
              <MenuItem onClick={handleLogout}>
                <ListItemIcon>
                  <LogoutIcon fontSize="small" />
                </ListItemIcon>
                <ListItemText primary="Sign Out" />
              </MenuItem>
            </Menu>
          </Box>
        </Box>
      </Toolbar>
    </AppBar>
  );
};

export default Header;