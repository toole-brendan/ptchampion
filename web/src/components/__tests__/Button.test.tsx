import { render, screen, fireEvent } from '../../test-utils';
import { describe, it, expect, vi } from 'vitest';
import { Button } from '@/components/ui/button';

describe('Button Component', () => {
  it('renders correctly with default props', () => {
    render(<Button>Click Me</Button>);
    const buttonElement = screen.getByRole('button', { name: /click me/i });
    expect(buttonElement).toBeInTheDocument();
    expect(buttonElement).toHaveClass('inline-flex');
  });

  it('renders a disabled button when disabled prop is true', () => {
    render(<Button disabled>Disabled Button</Button>);
    const buttonElement = screen.getByRole('button', { name: /disabled button/i });
    expect(buttonElement).toBeDisabled();
  });

  it('calls onClick handler when clicked', () => {
    const handleClick = vi.fn();
    render(<Button onClick={handleClick}>Clickable</Button>);
    
    const buttonElement = screen.getByRole('button', { name: /clickable/i });
    fireEvent.click(buttonElement);
    
    expect(handleClick).toHaveBeenCalledTimes(1);
  });

  it('applies variant classes correctly', () => {
    render(<Button variant="destructive">Delete</Button>);
    const buttonElement = screen.getByRole('button', { name: /delete/i });
    expect(buttonElement).toHaveClass('bg-destructive', { exact: false });
  });

  it('applies size classes correctly', () => {
    render(<Button size="sm">Small Button</Button>);
    const buttonElement = screen.getByRole('button', { name: /small button/i });
    expect(buttonElement).toHaveClass('h-8', { exact: false });
  });

  it('applies custom className', () => {
    render(<Button className="custom-class">Custom Button</Button>);
    const buttonElement = screen.getByRole('button', { name: /custom button/i });
    expect(buttonElement).toHaveClass('custom-class');
  });

  it('renders as a different element when asChild is true', () => {
    render(
      <Button asChild>
        <a href="https://example.com">Link Button</a>
      </Button>
    );
    
    const linkElement = screen.getByRole('link', { name: /link button/i });
    expect(linkElement).toHaveAttribute('href', 'https://example.com');
    expect(linkElement).toHaveClass('inline-flex', { exact: false });
  });
}); 