import React, { createContext, useContext, ReactNode, useState, useEffect } from 'react';

interface HeaderContextType {
  welcomeMessage: string;
  setWelcomeMessage: (message: string) => void;
  userName: string;
  setUserName: (name: string) => void;
}

const HeaderContext = createContext<HeaderContextType | undefined>(undefined);

export const HeaderProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
  const [welcomeMessage, setWelcomeMessage] = useState<string>('');
  const [userName, setUserName] = useState<string>(() => {
    // Initialize from localStorage if available
    const savedName = localStorage.getItem('ptc_userName');
    return savedName || '';
  });
  
  // Save userName to localStorage when it changes
  useEffect(() => {
    if (userName) {
      localStorage.setItem('ptc_userName', userName);
    }
  }, [userName]);

  return (
    <HeaderContext.Provider value={{ welcomeMessage, setWelcomeMessage, userName, setUserName }}>
      {children}
    </HeaderContext.Provider>
  );
};

export const useHeaderContext = (): HeaderContextType => {
  const context = useContext(HeaderContext);
  if (context === undefined) {
    throw new Error('useHeaderContext must be used within a HeaderProvider');
  }
  return context;
}; 