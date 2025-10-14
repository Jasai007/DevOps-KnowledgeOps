# 🔧 Chat History Troubleshooting Guide

## 🎯 **Quick Diagnosis**

### **Step 1: Check API Server**
```powershell
# Make sure API server is running on port 3001
$env:AWS_REGION="us-east-1"
$env:BEDROCK_AGENT_ID="MNJESZYALW"
cd backend
node server.js
```

### **Step 2: Test API Endpoints**
```powershell
# Test the health endpoint
curl http://localhost:3001/health

# Or run the test script
node test-chat-history.js
```

### **Step 3: Use Debug Mode**
```
# Open your browser to:
http://localhost:3002?debug=true

# This will show the debug panel to test API connections
```

## 🔍 **Common Issues & Solutions**

### **Issue 1: History Button Not Visible**
**Symptoms**: No history icon in header
**Solution**: 
- Check if `onHistoryClick` prop is passed to Header
- Verify Header component has the HistoryIcon import

### **Issue 2: History Drawer Not Opening**
**Symptoms**: Clicking history button does nothing
**Solution**:
- Check browser console for errors
- Verify ChatHistory component is imported in Layout
- Check if `chatHistoryOpen` state is working

### **Issue 3: No Sessions Listed**
**Symptoms**: History drawer opens but shows "No previous conversations"
**Solution**:
- Verify API server is running on port 3001
- Check if sessions are being created (look at API server logs)
- Test with debug mode: `http://localhost:3002?debug=true`

### **Issue 4: Sessions Not Loading**
**Symptoms**: Error messages when trying to load history
**Solution**:
- Check browser network tab for failed API calls
- Verify CORS is working (API server should show requests)
- Check if frontend is connecting to correct port (3001)

### **Issue 5: Frontend on Wrong Port**
**Symptoms**: Frontend running on port 3002 instead of 3000
**Solution**:
- Kill any process on port 3000: `taskkill /f /im node.exe`
- Restart frontend: `cd frontend && npm start`

## 🧪 **Testing Steps**

### **1. Test API Server Directly**
```bash
# Test session creation
curl -X POST http://localhost:3001/session \
  -H "Content-Type: application/json" \
  -d '{"action":"create"}'

# Test session listing
curl -X POST http://localhost:3001/session \
  -H "Content-Type: application/json" \
  -d '{"action":"list"}'
```

### **2. Test Frontend API Integration**
```javascript
// Open browser console and run:
fetch('http://localhost:3001/health')
  .then(r => r.json())
  .then(console.log)
  .catch(console.error);
```

### **3. Test Chat History Flow**
1. Start a conversation
2. Send 2-3 messages
3. Click history button
4. Check if session appears in list
5. Click "New Chat" button
6. Verify new session is created

## 🔧 **Debug Mode Usage**

### **Access Debug Panel**:
```
http://localhost:3002?debug=true
```

### **Debug Panel Features**:
- **Test API Health**: Checks if API server is responding
- **Create Session**: Tests session creation endpoint
- **List Sessions**: Tests session listing endpoint
- **View Raw Responses**: See exact API responses

## 🚨 **Emergency Fixes**

### **Quick Reset**:
```powershell
# Stop all Node processes
taskkill /f /im node.exe

# Restart API server
$env:AWS_REGION="us-east-1"
$env:BEDROCK_AGENT_ID="MNJESZYALW"
cd backend
node server.js

# In new terminal, restart frontend
cd frontend
npm start
```

### **Clear Browser Cache**:
```
# Hard refresh in browser
Ctrl + Shift + R

# Or clear localStorage
# Open browser console and run:
localStorage.clear();
```

## 📋 **Checklist for Working Chat History**

- [ ] ✅ API server running on port 3001
- [ ] ✅ Frontend running on port 3000 or 3002
- [ ] ✅ History button visible in header
- [ ] ✅ History drawer opens when clicked
- [ ] ✅ Sessions appear after sending messages
- [ ] ✅ Can switch between sessions
- [ ] ✅ "New Chat" button works
- [ ] ✅ Session memory persists

## 🎯 **Expected Behavior**

### **Normal Flow**:
1. **Start App**: Welcome message appears
2. **Send Message**: Session is created automatically
3. **Click History**: Drawer opens showing current session
4. **Send More Messages**: Session updates with message count
5. **New Chat**: Creates new session, old one saved in history
6. **Switch Sessions**: Can load previous conversations

### **Visual Indicators**:
- **Session Active Chip**: Shows "Session Active - Conversation Memory Enabled"
- **History Button**: Clock icon in header
- **Session List**: Shows date, message count, and preview
- **Current Session**: Highlighted in history list

## 💡 **Still Not Working?**

### **Check These Files**:
1. `backend/server.js` - Session management logic
2. `frontend/src/components/Chat/ChatHistory.tsx` - History UI
3. `frontend/src/components/Layout/Layout.tsx` - History integration
4. `frontend/src/services/api.ts` - API methods

### **Common Code Issues**:
- Missing imports
- Incorrect prop passing
- API endpoint mismatches
- State management problems

### **Get Help**:
Run the debug mode and share the results:
```
http://localhost:3002?debug=true
```

This will help identify exactly where the issue is occurring! 🚀