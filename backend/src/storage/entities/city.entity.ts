import { Column, Entity, OneToMany, PrimaryGeneratedColumn } from 'typeorm';

import { DistrictEntity } from './district.entity';

@Entity({ name: 'cities' })
export class CityEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ unique: true })
  slug!: string;

  @Column()
  name!: string;

  @OneToMany(() => DistrictEntity, (district) => district.city)
  districts!: DistrictEntity[];
}
