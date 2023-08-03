import { DatabaseEvent } from '../types'

export const databaseEventsArray: DatabaseEvent[] = [
  'SetupAP721',
  'DataStored',
  'DataOverwritten',
  'DataRemoved',
  'LogicUpdated',
  'RendererUpdated',
]

export const databaseEventsObject = {
  DATA_OVERWRITTEN: 'DataOverwritten',
  DATA_REMOVED: 'DataRemoved',
  DATA_STORED: 'DataStored',
  LOGIC_UPDATED: 'LogicUpdated',
  RENDERER_UPDATED: 'RendererUpdated',
  SETUP_AP721: 'SetupAP721',
}

export const databaseAbiEventsArray = [
  'event SetupAP721(address indexed ap721, address indexed sender, address indexed initialOwner, address logic,address renderer,address factory)',
  'event LogicUpdated(address indexed target, address indexed logic)',
  'event RendererUpdated(address indexed target, address indexed renderer)',
  'event DataStored(address indexed target, address indexed sender, uint256 indexed tokenId, address pointer)',
  'event DataOverwritten(address indexed target, address indexed sender, uint256 indexed tokenId, address pointer)',
  'event DataRemoved(address indexed target, address indexed sender, uint256 indexed tokenId)',
]
