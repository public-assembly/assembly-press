'use client';

import Editor from 'react-simple-code-editor';
import { useFunctionSelect } from 'context/FunctionSelectProvider';
import { highlight, languages } from 'prismjs';
import 'prismjs/components/prism-typescript';
import 'prismjs/components/prism-solidity';

import { 
    setupAP721Snippets,
    setLogicSnippets,
    setRendererSnippets,
    storeSnippets,
    overwriteSnippets,
} from '@/components/codeViewer/content/codeblocks';
import { Flex,CaptionLarge } from '../base';

type CodeViewerProps = {
  language: string;
};

export const CodeViewer = ({ language }: CodeViewerProps) => {

    // Get current selector from global contexta
    const {selector} = useFunctionSelect()

    // Map selector values to corresponding snippets
    const snippetsMap = {
        0: setupAP721Snippets,
        1: setLogicSnippets,
        2: setRendererSnippets,
        3: storeSnippets,
        4: overwriteSnippets,
    };
    
   // Find the correct snippet object using the selector, then get the language-specific snippet
   const code = snippetsMap[selector]?.[language];
   const headerName = language === 'solidity' ? 'Protocol' : (language === 'typescript' ? 'Frontend' : '');

  return (
<div>
<Flex className='flex-col w-full content-between border border-arsenic rounded-xl px-6 py-3'>
  <CaptionLarge className='text-platinum mb-4 align-left'>{headerName}</CaptionLarge> 
    
    <Editor
        value={code}
        onValueChange={null}    
        readOnly    
        highlight={code => highlight(code, languages[language], language)}        
        padding={10}
        style={{
          height: "400px",
          overflow: "auto",
        fontFamily: '"Fira code", "Fira Mono", monospace',
        fontSize: 12,
        color: "#fff"
        }}
    />
    </Flex>
    </div>
  );
};
