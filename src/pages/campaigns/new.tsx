import { useState } from 'react';
import { useRouter } from 'next/router';
import { createCampaign } from '../../hooks/useCampaign';

export default function NewCampaign() {
  const router = useRouter();
  const [form, setForm] = useState({
    template_id: '',
    code: '',
    name: '',
    description: '',
    status: 'draft',
    starts_at: '',
    ends_at: '',
    organization_name: ''
  });
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
    const { name, value } = e.target;
    setForm(prev => ({ ...prev, [name]: value }));
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      await createCampaign(form);
      router.push('/campaigns');
    } catch (err: any) {
      setError(err?.message ?? 'Error creating campaign');
    } finally {
      setLoading(false);
    }
  };

  return (
    <section className="max-w-2xl mx-auto p-4">
      <h1 className="text-2xl font-bold mb-4">Crear Nueva Campaña</h1>
      {error && <p className="text-red-600 mb-2">{error}</p>}
      <form onSubmit={handleSubmit} className="space-y-4">
        <input
          type="text"
          name="template_id"
          placeholder="ID de la plantilla"
          value={form.template_id}
          onChange={handleChange}
          required
          className="w-full border rounded p-2"
        />
        <input
          type="text"
          name="code"
          placeholder="Código (único)"
          value={form.code}
          onChange={handleChange}
          required
          className="w-full border rounded p-2"
        />
        <input
          type="text"
          name="name"
          placeholder="Nombre de la campaña"
          value={form.name}
          onChange={handleChange}
          required
          className="w-full border rounded p-2"
        />
        <textarea
          name="description"
          placeholder="Descripción"
          value={form.description}
          onChange={handleChange}
          className="w-full border rounded p-2"
        />
        <input
          type="datetime-local"
          name="starts_at"
          placeholder="Fecha inicio"
          value={form.starts_at}
          onChange={handleChange}
          className="w-full border rounded p-2"
        />
        <input
          type="datetime-local"
          name="ends_at"
          placeholder="Fecha fin"
          value={form.ends_at}
          onChange={handleChange}
          className="w-full border rounded p-2"
        />
        <input
          type="text"
          name="organization_name"
          placeholder="Nombre de la organización"
          value={form.organization_name}
          onChange={handleChange}
          className="w-full border rounded p-2"
        />
        <button
          type="submit"
          disabled={loading}
          className="bg-blue-600 text-white py-2 px-4 rounded hover:bg-blue-700"
        >
          {loading ? 'Guardando…' : 'Crear Campaña'}
        </button>
      </form>
    </section>
  );
}
