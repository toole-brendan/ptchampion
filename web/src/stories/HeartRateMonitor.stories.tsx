import type { Meta, StoryObj } from '@storybook/react';
import { HeartRateMonitor } from '../components/ui/heart-rate-monitor';

const meta: Meta<typeof HeartRateMonitor> = {
  title: 'Components/HeartRateMonitor',
  component: HeartRateMonitor,
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
type Story = StoryObj<typeof HeartRateMonitor>;

// Mock the HeartRateMonitor since we can't control its state directly in stories
// This story just displays the component with default state
export const Default: Story = {
  args: {
    onHeartRateChange: (hr) => console.log('Heart rate changed:', hr),
  },
};

// Just using empty props since we can't directly control internal state in stories
export const Minimized: Story = {
  args: {},
};

export const WithCustomClass: Story = {
  args: {
    className: 'w-80',
  },
}; 