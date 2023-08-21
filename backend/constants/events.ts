type RouterEvent =
  | 'FactoryRegistered'
  | 'PressRegistered'
  | 'TokenDataStored'
  | 'TokenDataOverwritten'
  | 'TokenDataRemoved'
  | 'PressDataUpdated';

export const routerEventsArray: RouterEvent[] = [
  'FactoryRegistered',
  'PressRegistered',
  'TokenDataStored',
  'TokenDataOverwritten',
  'TokenDataRemoved',
  'PressDataUpdated',
];

export const routerEventsObject = {
  FACTORY_REGISTERED: 'FactoryRegistered',
  PRESS_REGISTERED: 'PressRegistered',
  TOKEN_DATA_STORED: 'TokenDataStored',
  TOKEN_DATA_OVERWRITTEN: 'TokenDataOverwritten',
  TOKEN_DATA_REMOVED: 'TokenDataRemoved',
  PRESS_DATA_UPDATED: 'PressDataUpdated',
};

export const routerAbiEventsArray = [
  'event FactoryRegistered(address sender,address[] factories,bool[] statuses)',
  'event PressRegistered(address sender,address factory,address newPress)',
  'event TokenDataStored(address sender,address press,uint256[] tokenIds,address[] pointers)',
  'event TokenDataOverwritten(address sender,address press,uint256[] tokenIds,address[] pointers)',
  'event TokenDataRemoved(address sender,address press,uint256[] tokenIds)',
  'event PressDataUpdated(address sender,address press,address pointer)',
];
