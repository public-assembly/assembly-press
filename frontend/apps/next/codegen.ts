import type { CodegenConfig } from '@graphql-codegen/cli'

const config: CodegenConfig = {
  overwrite: true,
  schema: 'https://ap-op-goerli.hasura.app/v1/graphql',
  documents: 'gql/queries/*.graphql',
  generates: {
    'gql/sdk.generated.ts': {
      plugins: [
        'typescript',
        'typescript-operations',
        'typescript-graphql-request',
      ],
    },
  },
}

export default config
