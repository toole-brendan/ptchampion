import React from 'react';
import { MetricCard } from "@/components/ui/metric-card";
import { Activity, Clock, Users, Zap, BarChart, Heart } from "lucide-react";
import type { Meta, StoryObj } from "@storybook/react";

const meta: Meta<typeof MetricCard> = {
  title: "Components/MetricCard",
  component: MetricCard,
  parameters: {
    layout: "centered",
  },
  tags: ["autodocs"],
} satisfies Meta<typeof MetricCard>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  args: {
    title: "Total Users",
    value: 14298
  },
};

export const WithIcon: Story = {
  args: {
    title: "Active Sessions",
    value: 42,
    icon: Activity
  },
};

export const WithUnit: Story = {
  args: {
    title: "Average Session",
    value: 24,
    unit: "min",
    icon: Clock
  },
};

export const WithDescription: Story = {
  args: {
    title: "Total Users",
    value: 3720,
    description: "25% new users this month",
    icon: Users
  },
};

export const PositiveTrend: Story = {
  args: {
    title: "Conversion Rate",
    value: 12.8,
    unit: "%",
    change: 2.3,
    trend: "up"
  },
};

export const NegativeTrend: Story = {
  args: {
    title: "Churn Rate",
    value: 4.6,
    unit: "%",
    change: -1.2,
    trend: "down"
  },
};

export const NonNumeric: Story = {
  args: {
    title: 'Current Status',
    value: 'Excellent',
    description: 'Based on recent performance',
    icon: Heart
  },
};

export const Interactive: Story = {
  args: {
    title: 'Click Me',
    value: 'Details',
    description: 'This card is clickable',
    icon: Zap,
    onClick: () => alert('Card clicked!')
  },
}; 