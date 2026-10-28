// Reference for code quality, not a scaffold.
// A client component that renders all four states and shares its schema with the server.

'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const schema = z.object({
  startsAt: z.string().min(1, 'Pick a start time.'),
  note: z.string().max(500, 'Keep it under 500 characters.').optional(),
});
type Values = z.infer<typeof schema>;

type Props = {
  roomId: string;
  onCreated: (bookingId: string) => void;
};

export function BookingForm({ roomId, onCreated }: Props) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
    setError,
  } = useForm<Values>({ resolver: zodResolver(schema) });

  async function submit(values: Values) {
    const res = await fetch('/api/bookings', {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ ...values, roomId }),
    });

    if (!res.ok) {
      const body = await res.json().catch(() => null);
      setError('root', {
        message: body?.error?.message ?? 'Could not save the booking. Try again.',
      });
      return;
    }

    const { data } = await res.json();
    onCreated(data.id);
  }

  return (
    <form onSubmit={handleSubmit(submit)} noValidate className="space-y-4">
      <div>
        <label htmlFor="startsAt" className="block text-sm font-medium">
          Start time
        </label>
        <input
          id="startsAt"
          type="datetime-local"
          {...register('startsAt')}
          aria-invalid={errors.startsAt ? true : undefined}
          aria-describedby={errors.startsAt ? 'startsAt-error' : undefined}
          className="mt-1 w-full rounded-md border px-3 py-2"
        />
        {errors.startsAt && (
          <p id="startsAt-error" role="alert" className="mt-1 text-sm text-red-600">
            {errors.startsAt.message}
          </p>
        )}
      </div>

      <div>
        <label htmlFor="note" className="block text-sm font-medium">
          Note <span className="text-gray-500">(optional)</span>
        </label>
        <textarea id="note" rows={3} {...register('note')} className="mt-1 w-full rounded-md border px-3 py-2" />
      </div>

      {errors.root && (
        <p role="alert" className="rounded-md bg-red-50 px-3 py-2 text-sm text-red-700">
          {errors.root.message}
        </p>
      )}

      <button
        type="submit"
        disabled={isSubmitting}
        className="rounded-md bg-gray-900 px-4 py-2 text-white disabled:opacity-60"
      >
        {isSubmitting ? 'Saving…' : 'Book room'}
      </button>
    </form>
  );
}
