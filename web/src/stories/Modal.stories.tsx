import React, { useState, ReactNode } from 'react';
import { Meta, StoryObj } from '@storybook/react';
import { Modal, ModalFooter, ModalProps } from '../components/ui/modal';
import { Button, PrimaryButton, SecondaryButton } from '../components/ui/button';
import { X } from 'lucide-react';

const meta: Meta<typeof Modal> = {
  title: 'UI/Modal',
  component: Modal,
  tags: ['autodocs'],
  parameters: {
    layout: 'centered',
  },
  decorators: [
    (Story) => (
      <div className="bg-cream min-h-screen p-8">
        <Story />
      </div>
    ),
  ],
  argTypes: {
    isOpen: {
      control: 'boolean',
      description: 'Controls whether the modal is visible',
    },
    title: {
      control: 'text',
      description: 'Title displayed at the top of the modal',
    },
    description: {
      control: 'text',
      description: 'Optional description text below the title',
    },
    showCloseButton: {
      control: 'boolean',
      description: 'Whether to show the close button in the top-right corner',
    },
    withCorners: {
      control: 'boolean',
      description: 'Whether to show corner decorations',
    },
  },
};

export default meta;
type Story = StoryObj<typeof Modal>;

interface ModalWrapperProps extends Partial<Omit<ModalProps, 'isOpen' | 'onClose'>> {
  children: ReactNode;
}

const ModalWrapper = ({ children, ...args }: ModalWrapperProps) => {
  const [isOpen, setIsOpen] = useState(false);
  return (
    <>
      <Button onClick={() => setIsOpen(true)}>Open Modal</Button>
      <Modal 
        {...args} 
        isOpen={isOpen} 
        onClose={() => setIsOpen(false)}
      >
        {children}
      </Modal>
    </>
  );
};

export const Default: Story = {
  render: (args) => (
    <ModalWrapper {...args}>
      <p className="text-tactical-gray">
        This is a simple modal dialog with a plain message.
      </p>
    </ModalWrapper>
  ),
  args: {
    title: 'Information',
    description: 'Here is some important information for you.',
    showCloseButton: true,
  },
};

export const DeleteConfirmation: Story = {
  render: (args) => (
    <ModalWrapper {...args}>
      <p className="text-tactical-gray">
        Are you sure you want to delete this workout? This action cannot be undone.
      </p>
      <ModalFooter>
        <SecondaryButton onClick={() => console.log('Cancel clicked')}>
          Cancel
        </SecondaryButton>
        <PrimaryButton onClick={() => console.log('Delete clicked')}>
          Delete
        </PrimaryButton>
      </ModalFooter>
    </ModalWrapper>
  ),
  args: {
    title: 'Delete Workout',
    showCloseButton: true,
  },
};

export const WithActions: Story = {
  render: (args) => (
    <ModalWrapper 
      {...args} 
      actions={
        <>
          <SecondaryButton onClick={() => console.log('Cancel clicked')}>
            Cancel
          </SecondaryButton>
          <PrimaryButton onClick={() => console.log('Confirm clicked')}>
            Confirm
          </PrimaryButton>
        </>
      }
    >
      <p className="text-tactical-gray mb-4">
        This modal demonstrates using the new actions prop to easily add footer buttons.
      </p>
      <div className="bg-cream-dark p-4 rounded-md">
        <h3 className="text-command-black font-semibold mb-2">Alert Details</h3>
        <p className="text-sm text-tactical-gray">
          You're about to perform an important action. Please confirm or cancel.
        </p>
      </div>
    </ModalWrapper>
  ),
  args: {
    title: 'Confirm Action',
    description: 'Please review the information below',
    showCloseButton: true,
  },
};

export const OverflowingContent: Story = {
  render: (args) => (
    <ModalWrapper {...args}>
      <div className="space-y-4">
        {Array(20).fill(0).map((_, i) => (
          <p key={i} className="text-tactical-gray">
            This is paragraph {i+1} of content that will overflow the modal height, 
            demonstrating how scrolling works in the modal content area.
          </p>
        ))}
      </div>
      <ModalFooter>
        <PrimaryButton onClick={() => console.log('OK clicked')}>
          OK
        </PrimaryButton>
      </ModalFooter>
    </ModalWrapper>
  ),
  args: {
    title: 'Scrollable Content',
    description: 'This modal has content that exceeds the viewport height',
    showCloseButton: true,
  },
};

export const WithCornerDecor: Story = {
  render: (args) => (
    <ModalWrapper {...args}>
      <p className="text-tactical-gray">
        This modal demonstrates the military-style corner decorations.
      </p>
      <p className="text-tactical-gray mt-2">
        These corner elements add an additional visual element to the UI, 
        though they are off by default in modals to keep the interface clean.
      </p>
    </ModalWrapper>
  ),
  args: {
    title: 'With Corner Decoration',
    description: 'Optional military-style corner elements',
    showCloseButton: true,
    withCorners: true,
  },
}; 