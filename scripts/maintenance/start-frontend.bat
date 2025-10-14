@echo off
echo Starting DevOps KnowledgeOps Agent Frontend...
echo.

cd frontend
echo Installing dependencies...
call npm install

echo.
echo Starting development server...
echo Open http://localhost:3000 in your browser
echo.

call npm start