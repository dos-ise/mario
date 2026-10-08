import { computed, resource, ResourceRef } from '@angular/core';
import { extractGumbaTiles } from '../engine/gumba-tiles';

export function createEnemiesResource(
  enemiesMapResource: ResourceRef<Blob | undefined>
) {
  const params = computed(() => {
    const map = enemiesMapResource.value();
    return map ? { map } : undefined;
  });

  return resource({
    params,
    loader: ({ params }) => {
      if (!params?.map) {
        throw new Error('enemies map required');
      }
      return extractGumbaTiles(params.map);
    },
  });
}
