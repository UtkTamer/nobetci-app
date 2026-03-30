import {
  Column,
  Entity,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';

import { DistrictEntity } from './district.entity';
import { DutyRecordEntity } from './duty-record.entity';

@Entity({ name: 'pharmacies' })
export class PharmacyEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  name!: string;

  @Column()
  normalizedName!: string;

  @Column()
  address!: string;

  @Column()
  normalizedAddress!: string;

  @Column({ default: '' })
  phoneNumber!: string;

  @Column({ type: 'double precision', nullable: true })
  latitude!: number | null;

  @Column({ type: 'double precision', nullable: true })
  longitude!: number | null;

  @ManyToOne(() => DistrictEntity, (district) => district.pharmacies, {
    eager: true,
  })
  district!: DistrictEntity;

  @OneToMany(() => DutyRecordEntity, (dutyRecord) => dutyRecord.pharmacy)
  dutyRecords!: DutyRecordEntity[];
}
