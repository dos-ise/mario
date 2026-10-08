import { resource, ResourceRef } from '@angular/core';
import { Injectable } from '@angular/core';
import { Level } from '../engine/level';
import { initLevel } from './init-level';
import { initLevelOverview, LevelOverview } from './level-info';
import { embeddedAssets } from './embedded-assets';

@Injectable({ providedIn: 'root' })
export class LevelLoader {
  
  getLevelResource(levelKey: () => string | undefined): ResourceRef<Level> {
    
    return resource({
      params: levelKey,
      loader: ({ params }) => {
        const raw = embeddedAssets.levels[params];
        return Promise.resolve(raw ? toLevel(raw) : initLevel);
      },
      defaultValue: initLevel,
    });
    
  }

  getLevelOverviewResource(): ResourceRef<LevelOverview> {
    return resource({
      loader: () =>
        Promise.resolve(toLevelOverview(embeddedAssets.levels['overview'])),
      defaultValue: initLevelOverview,
    });
  }
}

function toLevelOverview(raw: unknown): LevelOverview {
  const correct =
    typeof raw === 'object' &&
    raw !== null &&
    'levels' in raw &&
    Array.isArray(raw.levels);

  if (!correct) {
    throw new Error('LevelOverview has an invalid structure!');
  }

  return raw as LevelOverview;
}

function toLevel(raw: unknown): Level {
  const correct =
    typeof raw === 'object' &&
    raw !== null &&
    'levelId' in raw &&
    typeof raw.levelId === 'number' &&
    'backgroundColor' in raw &&
    'items' in raw &&
    Array.isArray(raw.items);

  if (!correct) {
    throw new Error('Level has an invalid structure!');
  }

  const obj = raw as Record<string, unknown>;
  const gumbas = Array.isArray(obj['gumbas'])
    ? (obj['gumbas'] as { col: number; row: number }[])
    : [];
  return {
    ...obj,
    gumbas,
    levelGrid: [],
    rowCount: 0,
    colCount: 0,
  } as unknown as Level;
}
