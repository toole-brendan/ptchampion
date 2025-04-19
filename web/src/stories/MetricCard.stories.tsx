import type { Meta, StoryObj } from '@storybook/react';
import { MetricCard } from '../components/ui/metric-card';
import { Award, TrendingUp, Timer, Users } from 'lucide-react';

const meta: Meta<typeof MetricCard> = {
  title: 'Components/MetricCard',
  component: MetricCard,
  parameters: {
    layout: 'centered',
  },
  tags: ['autodocs'],
};

export default meta;
type Story = StoryObj<typeof MetricCard>;

export const Default: Story = {
  args: {
    label: 'TOTAL PUSH-UPS',
    value: '245',
  },
};

export const WithIcon: Story = {
  args: {
    label: 'LEADERBOARD RANK',
    value: '#12',
    icon: <Award size={24} />,
  },
};

export const WithPositiveTrend: Story = {
  args: {
    label: 'PROGRESS RATE',
    value: '87%',
    icon: <TrendingUp size={24} />,
    trend: {
      value: 5.3,
      isPositive: true,
    },
  },
};

export const WithNegativeTrend: Story = {
  args: {
    label: 'COMPLETION TIME',
    value: '2:23',
    icon: <Timer size={24} />,
    trend: {
      value: 12,
      isPositive: false,
    },
  },
};

export const Grid: Story = {
  render: () => (
    <div className="grid grid-cols-2 gap-4 max-w-xl">
      <MetricCard label="TOTAL PUSH-UPS" value="245" icon={<TrendingUp size={24} />} />
      <MetricCard label="LEADERBOARD RANK" value="#12" icon={<Award size={24} />} />
      <MetricCard 
        label="ACTIVE USERS" 
        value="1,294" 
        icon={<Users size={24} />}
        trend={{ value: 12.5, isPositive: true }}
      />
      <MetricCard 
        label="COMPLETION TIME" 
        value="2:23" 
        icon={<Timer size={24} />}
        trend={{ value: 8, isPositive: false }}
      />
    </div>
  ),
}; 