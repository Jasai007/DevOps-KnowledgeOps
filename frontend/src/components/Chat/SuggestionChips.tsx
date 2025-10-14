import React from 'react';
import {
  Box,
  Typography,
  Chip,
  Slide,
  useTheme,
  useMediaQuery,
} from '@mui/material';
import {
  Code as CodeIcon,
  Cloud as CloudIcon,
  Security as SecurityIcon,
  Build as BuildIcon,
  Monitor as MonitorIcon,
  Storage as StorageIcon,
} from '@mui/icons-material';

interface Suggestion {
  text: string;
  icon: React.ReactElement;
  category: string;
}

interface SuggestionChipsProps {
  onSuggestionClick: (suggestion: string) => void;
  show: boolean;
}

const DEMO_SUGGESTIONS: Suggestion[] = [
  { 
    text: "Help me troubleshoot EKS pod failures", 
    icon: <CloudIcon />, 
    category: "Kubernetes" 
  },
  { 
    text: "Design a CI/CD pipeline for microservices", 
    icon: <BuildIcon />, 
    category: "CI/CD" 
  },
  { 
    text: "What's the best monitoring setup for containers?", 
    icon: <MonitorIcon />, 
    category: "Monitoring" 
  },
  { 
    text: "How do I implement security scanning in my pipeline?", 
    icon: <SecurityIcon />, 
    category: "Security" 
  },
  { 
    text: "Show me Terraform best practices", 
    icon: <CodeIcon />, 
    category: "Infrastructure" 
  },
  { 
    text: "Help me optimize Docker images", 
    icon: <StorageIcon />, 
    category: "Containers" 
  },
];

const SuggestionChips: React.FC<SuggestionChipsProps> = ({ 
  onSuggestionClick, 
  show 
}) => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  const isTablet = useMediaQuery(theme.breakpoints.down('md'));

  if (!show) return null;

  return (
    <Slide direction="up" in={show}>
      <Box sx={{ 
        mt: { xs: 2, sm: 3 },
        px: { xs: 1, sm: 0 },
        pb: { xs: 10, sm: 2 }, // Extra padding on mobile for fixed input
      }}>
        <Typography 
          variant={isMobile ? "subtitle1" : "h6"} 
          gutterBottom 
          color="text.secondary"
          sx={{
            fontWeight: 600,
            mb: { xs: 1.5, sm: 2 },
            textAlign: { xs: 'center', sm: 'left' },
          }}
        >
          💡 Try these example queries:
        </Typography>
        
        <Box sx={{ 
          display: 'grid',
          gridTemplateColumns: {
            xs: '1fr',
            sm: 'repeat(2, 1fr)',
            md: 'repeat(3, 1fr)',
          },
          gap: { xs: 1, sm: 1.5 },
        }}>
          {DEMO_SUGGESTIONS.map((suggestion, index) => (
            <Chip
              key={index}
              icon={suggestion.icon}
              label={
                <Box>
                  <Typography 
                    variant="body2" 
                    sx={{ 
                      fontWeight: 500,
                      fontSize: { xs: '0.8rem', sm: '0.875rem' },
                      lineHeight: 1.3,
                    }}
                  >
                    {suggestion.text}
                  </Typography>
                  <Typography 
                    variant="caption" 
                    sx={{ 
                      opacity: 0.7,
                      fontSize: { xs: '0.7rem', sm: '0.75rem' },
                    }}
                  >
                    {suggestion.category}
                  </Typography>
                </Box>
              }
              onClick={() => onSuggestionClick(suggestion.text)}
              clickable
              variant="outlined"
              sx={{
                height: 'auto',
                py: { xs: 1, sm: 1.5 },
                px: { xs: 1.5, sm: 2 },
                borderRadius: 2,
                justifyContent: 'flex-start',
                textAlign: 'left',
                transition: 'all 0.2s ease-in-out',
                '& .MuiChip-label': {
                  display: 'block',
                  whiteSpace: 'normal',
                  textAlign: 'left',
                  width: '100%',
                },
                '& .MuiChip-icon': {
                  fontSize: { xs: '1.1rem', sm: '1.25rem' },
                  ml: 0.5,
                  mr: 1,
                },
                '&:hover': {
                  transform: 'translateY(-2px)',
                  boxShadow: theme.shadows[4],
                  borderColor: 'primary.main',
                  bgcolor: 'primary.50',
                },
                '&:active': {
                  transform: 'translateY(0px)',
                },
              }}
            />
          ))}
        </Box>
        
        <Box sx={{ 
          mt: { xs: 2, sm: 3 },
          textAlign: 'center',
        }}>
          <Typography 
            variant="body2" 
            color="text.secondary"
            sx={{
              fontStyle: 'italic',
              fontSize: { xs: '0.8rem', sm: '0.875rem' },
            }}
          >
            Or ask me anything about DevOps, Infrastructure, CI/CD, Security, or Monitoring!
          </Typography>
        </Box>
      </Box>
    </Slide>
  );
};

export default SuggestionChips;