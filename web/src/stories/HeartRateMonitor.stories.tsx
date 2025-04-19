import type { Meta, StoryObj } from '@storybook/react';
import { HeartRateMonitor } from '../components/ui/heart-rate-monitor';

const meta: Meta<typeof HeartRateMonitor> = {
  title: 'Components/HeartRateMonitor',
  component: HeartRateMonitor,
  parameters: {
    layout: 'centered',
  },
  tags: ['autodocs'],
  argTypes: {
    onHeartRateChange: { action: 'heartRateChanged' },
    className: { control: 'text' },
  },
};

export default meta;
type Story = StoryObj<typeof HeartRateMonitor>;

export const Default: Story = {
  args: {},
};

export const WithCustomClass: Story = {
  args: {
    className: 'w-80',
  },
};

export const Collapsed: Story = {
  args: {},
  parameters: {
    docs: {
      description: {
        story: 'The component starts in a collapsed state showing only a button. Click to expand.'
      }
    }
  }
};

// This is optional as it requires mocking the Web Bluetooth API
export const UnsupportedBrowser: Story = {
  args: {},
  parameters: {
    docs: {
      description: {
        story: 'The component displays a message when the browser does not support Web Bluetooth API.'
      }
    }
  },
  // You'd need to create a decorator to mock this behavior
  // decorators: [
  //   (Story) => {
  //     // Mock navigator.bluetooth as undefined
  //     const originalBluetooth = navigator.bluetooth;
  //     Object.defineProperty(navigator, 'bluetooth', {
  //       value: undefined,
  //       configurable: true,
  //     });
  //     
  //     // Return the story with the mocked navigator
  //     return <Story />;
  //   },
  // ],
}; 