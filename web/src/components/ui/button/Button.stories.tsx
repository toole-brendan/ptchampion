import type { Meta, StoryObj } from '@storybook/react';
import { Button } from '@/components/ui/button';

// More on how to set up stories at: https://storybook.js.org/docs/writing-stories#default-export
const meta = {
  title: 'UI/Button',
  component: Button,
  parameters: {
    // Optional parameter to center the component in the Canvas
    layout: 'centered',
  },
  // This component will have an automatically generated Autodocs entry: https://storybook.js.org/docs/writing-docs/autodocs
  tags: ['autodocs'],
  // More on argTypes: https://storybook.js.org/docs/api/argtypes
  argTypes: {
    variant: {
      control: 'select',
      options: ['default', 'primary', 'destructive', 'outline', 'secondary', 'secondary-fill', 'ghost', 'link'],
      description: 'The variant style of the button',
    },
    size: {
      control: 'select',
      options: ['default', 'sm', 'lg', 'icon'],
      description: 'The size of the button',
    },
    children: {
      control: 'text',
      description: 'The content of the button',
    },
    disabled: {
      control: 'boolean',
      description: 'Whether the button is disabled',
    },
    asChild: {
      control: 'boolean',
      description: 'Whether to render as a child element instead of a button',
    },
    uppercase: {
      control: 'boolean',
      description: 'Whether to use uppercase text (default: true)',
    },
  },
  args: {
    // More on args: https://storybook.js.org/docs/writing-stories/args
    children: 'Button',
    variant: 'primary',
    size: 'default',
    disabled: false,
    asChild: false,
    uppercase: true,
  },
} satisfies Meta<typeof Button>;

export default meta;
type Story = StoryObj<typeof Button>;

// More on writing stories with args: https://storybook.js.org/docs/writing-stories/args
export const Primary: Story = {
  args: {
    variant: 'primary',
    children: 'Primary',
  },
};

export const Default: Story = {
  args: {
    variant: 'default',
    children: 'Default (Primary)',
  },
};

export const Secondary: Story = {
  args: {
    variant: 'outline',
    children: 'Secondary (Outline)',
  },
};

export const SecondaryFill: Story = {
  args: {
    variant: 'secondary-fill',
    children: 'Secondary Fill',
  },
};

export const Destructive: Story = {
  args: {
    variant: 'destructive',
    children: 'Destructive',
  },
};

export const Outline: Story = {
  args: {
    variant: 'outline',
    children: 'Outline',
  },
};

export const Ghost: Story = {
  args: {
    variant: 'ghost',
    children: 'Ghost',
  },
};

export const Link: Story = {
  args: {
    variant: 'link',
    children: 'Link Button',
  },
};

export const Small: Story = {
  args: {
    size: 'sm',
    children: 'Small Button',
  },
};

export const Large: Story = {
  args: {
    size: 'lg',
    children: 'Large Button',
  },
};

export const Icon: Story = {
  args: {
    size: 'icon',
    children: '🔍',
    'aria-label': 'Search',
  },
};

export const Disabled: Story = {
  args: {
    disabled: true,
    children: 'Disabled Button',
  },
};

export const LowercaseText: Story = {
  args: {
    uppercase: false,
    children: 'Lowercase Text',
  },
};

export const WithCustomClassName: Story = {
  args: {
    className: 'bg-purple-600 hover:bg-purple-700',
    children: 'Custom Class',
  },
};

// Example with asChild
export const AsLink: Story = {
  render: (args: React.ComponentProps<typeof Button>) => (
    <Button {...args} asChild>
      <a href="https://example.com">Link as Button</a>
    </Button>
  ),
}; 