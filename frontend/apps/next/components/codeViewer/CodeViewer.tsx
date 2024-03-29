'use client';

import Editor from 'react-simple-code-editor';
import { useFunctionSelect } from 'context/FunctionSelectProvider';
import { highlight, languages } from 'prismjs';
import 'prismjs/themes/prism-solarizedlight.css';
import 'prismjs/components/prism-typescript';
import 'prismjs/components/prism-solidity';

import {
  setupSnippets,
  storeTokenDataSnippets,
  overwriteTokenDataSnippets,
  updatePressDataSnippets,
} from '@/components/codeViewer/content/codeblocks';

type CodeViewerProps = {
  language: string;
};

export const CodeViewer = ({ language }: CodeViewerProps) => {
  // Get current selector from global contexta
  const { selector } = useFunctionSelect();

  // Map selector values to corresponding snippets
  const snippetsMap = {
    0: setupSnippets,
    1: storeTokenDataSnippets,
    2: overwriteTokenDataSnippets,
    3: updatePressDataSnippets,
  };

  // Find the correct snippet object using the selector, then get the language-specific snippet
  const code = snippetsMap[selector]?.[language];

  return (
    <>
      <Editor
        value={code}
        onValueChange={null}
        readOnly
        highlight={(code) => highlight(code, languages[language], language)}
        padding={16}
        style={{
          overflow: 'auto',
          fontFamily: '"Fira code", "Fira Mono", monospace',
          fontSize: 13,
          color: '#E4E4E4',
          height: '432px',
        }}
        textareaClassName='focus:outline-none'
      />
    </>
  );
};
