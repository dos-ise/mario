import { computed, resource, ResourceRef } from "@angular/core";
import { extractHeroTiles } from "../engine/hero-tiles";

export function createHeroResource(
  heroMapResource: ResourceRef<Blob | undefined>,
) {

  const params = computed(() => {
    const heroMap = heroMapResource.value();
    return !heroMap
      ? undefined
      : {
          heroMap,
        };
  });

  return resource({
    params,
    loader: (loderParams) => {
      const { heroMap } = loderParams.params;
      return extractHeroTiles(heroMap);
    },
  });
}
