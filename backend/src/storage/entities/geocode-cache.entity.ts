import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity({ name: 'geocode_cache' })
export class GeocodeCacheEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ unique: true })
  addressKey!: string;

  @Column()
  rawAddress!: string;

  @Column({ type: 'double precision' })
  latitude!: number;

  @Column({ type: 'double precision' })
  longitude!: number;

  @Column({ type: 'datetime' })
  lastResolvedAt!: Date;
}
