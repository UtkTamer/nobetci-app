import {
  Column,
  Entity,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';

import { DutyRecordEntity } from './duty-record.entity';
import { CityEntity } from './city.entity';
import { PharmacyEntity } from './pharmacy.entity';

@Entity({ name: 'districts' })
@Unique(['city', 'slug'])
export class DistrictEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  name!: string;

  @Column()
  slug!: string;

  @ManyToOne(() => CityEntity, (city) => city.districts, { eager: true })
  city!: CityEntity;

  @OneToMany(() => PharmacyEntity, (pharmacy) => pharmacy.district)
  pharmacies!: PharmacyEntity[];

  @OneToMany(() => DutyRecordEntity, (dutyRecord) => dutyRecord.district)
  dutyRecords!: DutyRecordEntity[];
}
