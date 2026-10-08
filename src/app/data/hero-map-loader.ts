import { resource, ResourceRef } from '@angular/core';
import { Injectable } from '@angular/core';
import { dataUrlToBlob } from './data-url';
import { embeddedAssets } from './embedded-assets';

@Injectable({ providedIn: 'root' })
export class HeroMapLoader {
  getHeroMapResource(): ResourceRef<Blob | undefined> {
    return resource({
      loader: () => dataUrlToBlob(embeddedAssets.hero),
    });
  }
}