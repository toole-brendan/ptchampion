# Function to check git status and push all changes
gitsave() {
  echo "📊 Git Status:"
  git status
  
  echo "\n🔄 Adding all changes..."
  git add .
  
  echo "\n💾 Committing changes..."
  git commit -m "Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')"
  
  echo "\n⬆️ Pushing to remote..."
  git push
  
  echo "\n✅ Done!"
} 

# Short alias for running gitsave.sh
alias gsv="/Users/brendantoole/projects/ptchampion/gitsave.sh" 