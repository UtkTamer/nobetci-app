import { Column, Entity, ManyToOne, PrimaryGeneratedColumn } from 'typeorm';

import { DistrictEntity } from './district.entity';
import { PharmacyEntity } from './pharmacy.entity';

@Entity({ name: 'duty_records' })
export class DutyRecordEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @ManyToOne(() => PharmacyEntity, (pharmacy) => pharmacy.dutyRecords, {
    eager: true,
  })
  pharmacy!: PharmacyEntity;

  @ManyToOne(() => DistrictEntity, (district) => district.dutyRecords, {
    eager: true,
  })
  district!: DistrictEntity;

  @Column()
  citySlug!: string;

  @Column()
  cityDisplayName!: string;

  @Column()
  source!: string;

  @Column()
  sourceUrl!: string;

  @Column({ type: 'timestamp', nullable: true })
  dutyStart!: Date | null;

  @Column({ type: 'timestamp', nullable: true })
  dutyEnd!: Date | null;

  @Column({ type: 'timestamp' })
  lastVerifiedAt!: Date;

  @Column({ type: 'boolean', default: true })
  isActive!: boolean;
}
