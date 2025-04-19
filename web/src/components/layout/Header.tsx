import React from 'react';
import { Menu as MenuIcon } from 'lucide-react';
import { Button } from "@/components/ui/button";

interface HeaderProps {
  onMenuClick: () => void;
}

const Header: React.FC<HeaderProps> = ({ onMenuClick }) => {
  return (
    <header className="sticky top-0 z-30 flex h-14 items-center gap-4 border-b bg-background px-4 sm:static sm:h-auto sm:border-0 sm:bg-transparent sm:px-6 md:hidden">
      {/* Mobile Menu Button */}
      <Button
        variant="outline"
        size="icon"
        className="md:hidden" // Only show on smaller than md screens
        onClick={onMenuClick}
        aria-label="Toggle Menu"
      >
        <MenuIcon className="size-5" />
      </Button>
      {/* You could add other header elements here if needed, like a logo or page title */}
    </header>
  );
};

export default Header; 