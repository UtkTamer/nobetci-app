import { Column, Entity, PrimaryGeneratedColumn } from 'typeorm';

@Entity({ name: 'source_fetch_runs' })
export class SourceFetchRunEntity {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  citySlug!: string;

  @Column()
  source!: string;

  @Column()
  status!: 'success' | 'failed';

  @Column({ type: 'int', default: 0 })
  recordCount!: number;

  @Column({ type: 'text', nullable: true })
  errorMessage!: string | null;

  @Column({ type: 'datetime' })
  startedAt!: Date;

  @Column({ type: 'datetime' })
  finishedAt!: Date;
}
