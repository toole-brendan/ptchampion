# PT Champion

PT Champion is a fitness evaluation application that uses computer vision to track and evaluate military exercises. The app features global and local leaderboards, exercise tracking, and form analysis powered by TensorFlow's PoseNet model.

## Features

- **Exercise Tracking**: Monitor push-ups, pull-ups, sit-ups, and running performance
- **Computer Vision Analysis**: Real-time form analysis and feedback using TensorFlow and PoseNet
- **Leaderboards**: Compare your performance with others globally or locally
- **Personalized Feedback**: Get real-time form correction and improvement tips
- **Progress Tracking**: Monitor your performance over time with detailed history

## Technology Stack

- **Frontend**: React with Tailwind CSS and shadcn UI components
- **Backend**: Node.js/Express API
- **Database**: PostgreSQL with Drizzle ORM
- **Authentication**: Passport.js with local strategy
- **Computer Vision**: TensorFlow.js and PoseNet model

## Getting Started

### Prerequisites

- Node.js (v18+)
- PostgreSQL database
- Git

### Installation

1. Clone the repository:
   ```
   git clone <repository-url>
   cd pt-champion
   ```

2. Install dependencies:
   ```
   npm install
   ```

3. Set up environment variables by creating a `.env` file:
   ```
   DATABASE_URL=postgres://user:password@localhost:5432/pt_champion
   SESSION_SECRET=your-secret-key
   ```

4. Initialize the database:
   ```
   npm run db:push
   ```

5. Start the development server:
   ```
   npm run dev
   ```

6. Open your browser and navigate to `http://localhost:5000`

## Usage

1. **Register/Login**: Create an account or login to access the application
2. **Select Exercise**: Choose from push-ups, pull-ups, sit-ups, or running
3. **Allow Camera Access**: Position yourself so the camera can track your form
4. **Perform Exercise**: Follow the on-screen guidance and receive real-time feedback
5. **Complete Session**: Finish your workout to save your score and form rating
6. **View Progress**: Check your history and leaderboard ranking

## Deployment

See the [DEPLOYMENT.md](./DEPLOYMENT.md) file for detailed instructions on deploying the application to AWS.

## License

This project is licensed under the MIT License - see the LICENSE file for details.