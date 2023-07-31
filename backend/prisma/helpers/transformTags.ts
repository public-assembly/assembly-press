import { Prisma } from '@prisma/client'
import { Tag } from '../../interfaces/transactionInterfaces'

export function transformTags(tags: Prisma.JsonValue): Tag[] {
  // check if tags is an array
  if (Array.isArray(tags)) {
    // if tags is an array, map over it and transform each item into a Tag
    return tags.map((tag) => {
      if (
        typeof tag === 'object' &&
        tag !== null &&
        'name' in tag &&
        'value' in tag
      ) {
        return {
          name: String(tag.name),
          value: String(tag.value),
        }
      } else {
        // if the tag is not an object with 'name' and 'value' fields, return a default Tag
        return { name: '', value: '' }
      }
    })
  } else {
    // If tags is not an array, return an empty array
    return []
  }
}
