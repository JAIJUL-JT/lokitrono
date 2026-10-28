import { useState } from 'react';
import { supabase } from '../utils/supabaseClient';

export default function SearchEvents() {
  const [city, setCity] = useState('');
  const [dateFilter, setDateFilter] = useState('today'); // today | week | custom
  const [customStart, setCustomStart] = useState('');
  const [customEnd, setCustomEnd] = useState('');
  const [results, setResults] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSearch = async () => {
    setLoading(true);
    setError(null);
    try {
      const params: any = { p_date_filter: dateFilter };
      if (dateFilter === 'custom') {
        params.p_start = customStart;
        params.p_end = customEnd;
      }
      if (city) params.p_city = city;
      const { data, error } = await supabase.rpc('search_events', params);
      if (error) throw error;
      setResults(data || []);
    } catch (e: any) {
      setError(e.message || 'Error searching events');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="p-4">
      <h2 className="text-xl font-semibold mb-4">Buscar eventos activos</h2>
      <div className="flex flex-col md:flex-row gap-2 mb-4">
        <select
          value={dateFilter}
          onChange={e => setDateFilter(e.target.value)}
          className="border rounded p-2"
        >
          <option value="today">Hoy</option>
          <option value="week">Esta semana</option>
          <option value="custom">Rango personalizado</option>
        </select>
        {dateFilter === 'custom' && (
          <>
            <input
              type="date"
              value={customStart}
              onChange={e => setCustomStart(e.target.value)}
              className="border rounded p-2"
            />
            <input
              type="date"
              value={customEnd}
              onChange={e => setCustomEnd(e.target.value)}
              className="border rounded p-2"
            />
          </>
        )}
        <input
          type="text"
          placeholder="Ciudad (Bilbao, Barakaldo…)"
          value={city}
          onChange={e => setCity(e.target.value)}
          className="border rounded p-2 flex-1"
        />
        <button
          onClick={handleSearch}
          disabled={loading}
          className="bg-green-600 text-white py-2 px-4 rounded"
        >
          {loading ? 'Cargando…' : 'Buscar'}
        </button>
      </div>
      {error && <p className="text-red-600">{error}</p>}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {results.map(ev => (
          <div key={ev.id} className="border rounded p-3 shadow-sm">
            <h3 className="font-bold">{ev.title}</h3>
            <p>{ev.description}</p>
            <p className="text-sm text-gray-600">
              {new Date(ev.start_date).toLocaleString()} – {ev.end_date ? new Date(ev.end_date).toLocaleString() : 'Sin fin'}
            </p>
            <p className="text-sm">{ev.location_name || ev.address}</p>
            <p className="text-xs text-gray-500">Campaña: {ev.campaign_name}</p>
          </div>
        ))}
      </div>
    </div>
  );
}
