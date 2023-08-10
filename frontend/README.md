## ap-hooks

`ap-hooks` is a small set of React hooks designed to help you build applications on the Assembly Press framework.

The hooks included in this directory are located within `packages/ap-hooks`.

## Overview

Each of these hooks is built identically using [wagmi prepare hooks](https://wagmi.sh/react/prepare-hooks). This means that every app consuming this package must also consume wagmi and viem.

`useSetupAP721`
Deploy and configure an ERC721 contract which represents a row in the database.

`useStore`
Store generic data in the database and mint a storage receipt.

`useOverwrite`
Overwrite data associated with an existing token.

`useRemove`
Remove data associated with an existing token.

`useSetLogic`
Update the logic contract associated with a given row.

`useSetRenderer`
Update the renderer contract associated with a given row.

In addition to the hooks above, this package includes the ABI for `AP721DatabaseV1.sol` which is located within `src/contracts`.

---

`ap-hooks` are tested against a Next.js sandbox located in this directory within `apps/next`. Any contributions to these hooks should include an example implementation in this app.
