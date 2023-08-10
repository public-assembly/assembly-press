'use client'

import { createContext, useContext, useState, useEffect, ReactNode } from "react";

const FunctionSelectContext = createContext<{
    selector: number;
    setSelector: (value: number) => void;
  }>({
    selector: 0,
    setSelector: () => {},
  });

  interface FunctionSelectProviderProps {
    children: ReactNode;
    defaultSelector?: number;
  }
  

  export function FunctionSelectProvider({ children, defaultSelector = 0 }: FunctionSelectProviderProps) {
    const [selector, setSelector] = useState(defaultSelector);
    const value = { selector, setSelector };
  
    return <FunctionSelectContext.Provider value={value}>{children}</FunctionSelectContext.Provider>;
  }

  export function useFunctionSelect() {
    const context = useContext(FunctionSelectContext);
  
    if (context === undefined) {
      throw new Error("useFunctionSelect must be used within FunctionSelectProvider");
    }
  
    return context;
  }


