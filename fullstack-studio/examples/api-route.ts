// Reference for code quality, not a scaffold. Adapt names and rules to the project.
// A route handler that validates, authorises, and answers in one shape.

import { NextResponse } from 'next/server';
import { z } from 'zod';
import { auth } from '@/lib/auth';
import { prisma } from '@/lib/db';

const CreateBooking = z
  .object({
    roomId: z.string().uuid(),
    startsAt: z.coerce.date(),
    endsAt: z.coerce.date(),
    note: z.string().trim().max(500).optional(),
  })
  .strict()
  .refine((v) => v.endsAt > v.startsAt, {
    message: 'endsAt must be after startsAt',
    path: ['endsAt'],
  });

export async function POST(request: Request) {
  const session = await auth();
  if (!session?.user) {
    return NextResponse.json(
      { error: { code: 'UNAUTHORISED', message: 'Sign in to book a room.' } },
      { status: 401 },
    );
  }

  const body = await request.json().catch(() => null);
  const parsed = CreateBooking.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json(
      {
        error: {
          code: 'VALIDATION',
          message: 'Check the highlighted fields.',
          fields: parsed.error.flatten().fieldErrors,
        },
      },
      { status: 400 },
    );
  }

  const { roomId, startsAt, endsAt, note } = parsed.data;

  // Authorisation lives in the query: a room the user may not book is simply absent.
  const room = await prisma.room.findFirst({
    where: { id: roomId, venue: { members: { some: { userId: session.user.id } } } },
  });
  if (!room) {
    return NextResponse.json(
      { error: { code: 'NOT_FOUND', message: 'That room is not available to you.' } },
      { status: 404 },
    );
  }

  const clash = await prisma.booking.findFirst({
    where: { roomId, startsAt: { lt: endsAt }, endsAt: { gt: startsAt } },
    select: { id: true },
  });
  if (clash) {
    return NextResponse.json(
      { error: { code: 'CONFLICT', message: 'That slot overlaps an existing booking.' } },
      { status: 409 },
    );
  }

  const booking = await prisma.booking.create({
    data: { roomId, startsAt, endsAt, note, userId: session.user.id },
  });

  return NextResponse.json({ data: booking }, { status: 201 });
}
