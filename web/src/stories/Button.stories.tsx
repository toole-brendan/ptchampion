import type { Meta, StoryObj } from '@storybook/react';
import { Button } from '../components/ui/button';
import { Award, Plus, Trash } from 'lucide-react';

const meta: Meta<typeof Button> = {
  title: 'Components/Button',
  component: Button,
  parameters: {
    layout: 'centered',
    backgrounds: {
      default: 'cream',
      values: [
        { name: 'cream', value: '#F4F1E6' },
      ],
    },
  },
  tags: ['autodocs'],
  argTypes: {
    variant: {
      control: 'select',
      options: ['default', 'destructive', 'outline', 'secondary', 'ghost', 'link'],
    },
    size: {
      control: 'select',
      options: ['default', 'sm', 'lg', 'icon'],
    },
  },
  decorators: [
    (Story) => (
      <div className="bg-cream p-6 min-h-[200px] flex items-center justify-center">
        <Story />
      </div>
    ),
  ],
};

export default meta;
type Story = StoryObj<typeof Button>;

export const Default: Story = {
  args: {
    children: 'START WORKOUT',
  },
};

export const Secondary: Story = {
  args: {
    variant: 'secondary',
    children: 'FILTER RESULTS',
  },
};

export const Outline: Story = {
  args: {
    variant: 'outline',
    children: 'VIEW DETAILS',
  },
};

export const WithIcon: Story = {
  args: {
    children: (
      <>
        <Plus size={16} />
        NEW SESSION
      </>
    ),
  },
};

export const DestructiveWithIcon: Story = {
  args: {
    variant: 'destructive',
    children: (
      <>
        <Trash size={16} />
        DELETE
      </>
    ),
  },
};

export const Large: Story = {
  args: {
    size: 'lg',
    children: 'START WORKOUT',
  },
};

export const Small: Story = {
  args: {
    size: 'sm',
    children: 'FILTER',
  },
};

export const IconOnly: Story = {
  args: {
    size: 'icon',
    'aria-label': 'Award',
    children: <Award />,
  },
};

export const ButtonGrid: Story = {
  render: () => (
    <div className="grid grid-cols-3 gap-4">
      <Button variant="default">DEFAULT</Button>
      <Button variant="secondary">SECONDARY</Button>
      <Button variant="outline">OUTLINE</Button>
      <Button variant="destructive">DESTRUCTIVE</Button>
      <Button variant="ghost">GHOST</Button>
      <Button variant="link">LINK</Button>
    </div>
  ),
}; 