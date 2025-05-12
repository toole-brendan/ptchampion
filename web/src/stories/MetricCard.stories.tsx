import type { Meta, StoryObj } from '@storybook/react';
import { MetricCard } from '../components/ui/metric-card';
import { Award, Clock, Map } from 'lucide-react';

const meta: Meta<typeof MetricCard> = {
  title: 'Components/MetricCard',
  component: MetricCard,
  parameters: {
    layout: 'centered',
    backgrounds: {
      default: 'cream',
      values: [
        { name: 'cream', value: '#F4F1E6' },
      ],
    },
  },
  decorators: [
    (Story) => (
      <div className="bg-cream p-6 min-h-[200px] w-full max-w-md flex items-center justify-center">
        <Story />
      </div>
    ),
  ],
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof MetricCard>;

export const Default: Story = {
  args: {
    title: 'Reps',
    value: '24',
    icon: Award,
  },
};

export const WithIcon: Story = {
  args: {
    title: 'Distance',
    value: '2.5 mi',
    icon: Map,
  },
};

export const WithDescription: Story = {
  args: {
    title: 'Time',
    value: '12:34',
    description: 'min:sec',
    icon: Clock,
  },
};

export const WithTrend: Story = {
  args: {
    title: 'Weekly Progress',
    value: 42,
    description: 'Total workouts', 
    change: 15,
    trend: 'up',
  },
}; 