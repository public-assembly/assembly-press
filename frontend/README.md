## ap-hooks

`ap-hooks` is a small set of React hooks designed to help you build applications on the Assembly Press framework.

The hooks included in this directory are located within `packages/ap-hooks`.

## Overview

Each of these hooks is built identically using [wagmi prepare hooks](https://wagmi.sh/react/prepare-hooks). This means that every app consuming this package must also consume wagmi and viem.

`useSetup`
Deploy and configure a Press contract.

`useStoreTokenData`
Store generic data in a target Press contract and receive storage receipt(s).

`useOverwriteTokenData`
Overwrite data associated with an existing token.

`useUpdatePressData`
Store/overwrite/remove data associated with an existing Press.

In addition to the hooks above, this package includes the ABI for `Router.sol` which is located within `src/contracts`.

---


`ap-hooks` are tested against a Next.js sandbox located in this directory within `apps/next`. Any contributions to these hooks should include an example implementation in this app.

